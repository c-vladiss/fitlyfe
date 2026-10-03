package com.fitlyfe.fitlyfe_backend.graphql

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import com.fitlyfe.fitlyfe_backend.common.GraphQLTestClient
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import java.util.UUID

class GraphQLErrorHandlingTest : AbstractIntegrationTest() {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

    @Autowired
    lateinit var objectMapper: ObjectMapper

    private lateinit var client: GraphQLTestClient

    @BeforeEach
    fun setUp() {
        client = GraphQLTestClient(restTemplate, objectMapper)
    }

    private fun JsonNode.firstError(): JsonNode = path("errors").path(0)

    private fun JsonNode.classification() = firstError().path("extensions").path("classification").asText()

    @Test
    fun `unauthenticated request is rejected`() {
        val result = client.execute("{ userMealTypes { id } }")
        assertEquals("FORBIDDEN", result.classification())
        assertEquals("Access denied", result.firstError().path("message").asText())
    }

    @Test
    fun `unknown id is reported as NOT_FOUND`() {
        val result = client.execute(
            "mutation(\$id: ID!) { deleteMealEntry(entryId: \$id) }",
            mapOf("id" to UUID.randomUUID().toString()),
            asUser = UUID.randomUUID(),
        )
        assertEquals("NOT_FOUND", result.classification())
    }

    @Test
    fun `malformed input is reported as BAD_REQUEST`() {
        val user = UUID.randomUUID()

        val badId = client.execute("mutation { deleteMealEntry(entryId: \"not-a-uuid\") }", asUser = user)
        assertEquals("BAD_REQUEST", badId.classification())

        val badDate = client.execute("{ dailyNutrition(date: \"2024-13-45\") { id } }", asUser = user)
        assertEquals("BAD_REQUEST", badDate.classification())
    }

    @Test
    fun `touching another user's data is rejected`() {
        val owner = UUID.randomUUID()
        val mealTypeId = client.executeOk("{ userMealTypes { id } }", asUser = owner)
            .path("userMealTypes").path(0).path("id").asText()

        val result = client.execute(
            "mutation(\$id: ID!) { deleteUserMealType(id: \$id) }",
            mapOf("id" to mealTypeId),
            asUser = UUID.randomUUID(),
        )
        assertEquals("BAD_REQUEST", result.classification())
        assertEquals("Meal type does not belong to user", result.firstError().path("message").asText())

        // The owner's data is untouched
        val remaining = client.executeOk("{ userMealTypes { id } }", asUser = owner).path("userMealTypes")
        assertEquals(mealTypeId, remaining.path(0).path("id").asText())
    }

    @Test
    fun `graphiql is not served unless enabled`() {
        val response = restTemplate.getForEntity("/graphiql", String::class.java)
        // No handler is mapped, so the request falls through to Spring's error path
        // (401 or 404 depending on the security chain) instead of returning the editor
        assertTrue(response.statusCode.is4xxClientError, "got ${response.statusCode}")
        assertFalse(response.body.orEmpty().contains("graphiql", ignoreCase = true))
    }
}
