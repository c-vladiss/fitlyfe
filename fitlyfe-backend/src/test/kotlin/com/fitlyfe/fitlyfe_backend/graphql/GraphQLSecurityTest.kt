package com.fitlyfe.fitlyfe_backend.graphql

import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue

class GraphQLSecurityTest : AbstractIntegrationTest() {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

    @Test
    fun `should return error when accessing protected graphql resource without token`() {
        val query = "{ \"query\": \"{ workoutSessions { id } }\" }"
        val headers = HttpHeaders()
        headers.contentType = MediaType.APPLICATION_JSON

        val request = HttpEntity(query, headers)
        val response = restTemplate.postForEntity("/graphql", request, String::class.java)

        // GraphQL endpoint returns 200 even for errors, but the body contains error info
        assertEquals(HttpStatus.OK, response.statusCode)

        val body = response.body ?: ""
        // Should contain error in the response - either security related or "errors" field
        assertTrue(
            body.contains("errors") ||
            body.contains("Unauthorized") ||
            body.contains("Access is denied") ||
            body.contains("Forbidden") ||
            body.contains("FORBIDDEN"),
            "Expected error response but got: $body"
        )
    }
}
