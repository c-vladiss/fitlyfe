package com.fitlyfe.fitlyfe_backend.graphql

import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.api.user.repository.UserRepository
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import com.fitlyfe.fitlyfe_backend.common.GraphQLTestClient
import jakarta.persistence.EntityManagerFactory
import org.hibernate.SessionFactory
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import java.util.UUID

class CurrentUserResolutionTest : AbstractIntegrationTest() {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @Autowired
    lateinit var userRepository: UserRepository

    @Autowired
    lateinit var entityManagerFactory: EntityManagerFactory

    private lateinit var client: GraphQLTestClient

    private val statistics get() = entityManagerFactory.unwrap(SessionFactory::class.java).statistics

    @BeforeEach
    fun setUp() {
        client = GraphQLTestClient(restTemplate, objectMapper)
    }

    @Test
    fun `first request from an unknown user creates the user`() {
        val supabaseId = UUID.randomUUID()
        assertNull(userRepository.findBySupabaseId(supabaseId))

        client.executeOk("{ userMealTypes { id } }", asUser = supabaseId)

        val user = userRepository.findBySupabaseId(supabaseId)
        assertNotNull(user)
        assertEquals("$supabaseId@test.fitlyfe", user!!.email)
    }

    @Test
    fun `requests from an existing user do not write the user row`() {
        val supabaseId = UUID.randomUUID()
        client.executeOk("mutation { syncUser { id } }", asUser = supabaseId)
        // Warm up the per-user template rows so the measured request is a pure read
        client.executeOk("{ userMealTypes { id } }", asUser = supabaseId)
        val before = userRepository.findBySupabaseId(supabaseId)!!

        statistics.clear()
        client.executeOk("{ userMealTypes { id } }", asUser = supabaseId)
        client.executeOk("{ workoutSessions { id } }", asUser = supabaseId)

        assertEquals(0, statistics.entityUpdateCount, "user row should not be updated")
        assertEquals(0, statistics.entityInsertCount)
        assertEquals(before.updatedAt, userRepository.findBySupabaseId(supabaseId)!!.updatedAt)
    }
}
