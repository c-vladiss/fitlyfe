package com.fitlyfe.fitlyfe_backend.common

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.http.HttpEntity
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import java.util.UUID

/** Posts GraphQL documents to /graphql as a given test user. */
class GraphQLTestClient(
    private val restTemplate: TestRestTemplate,
    private val objectMapper: ObjectMapper,
) {
    fun execute(
        document: String,
        variables: Map<String, Any?> = emptyMap(),
        asUser: UUID? = null,
        operationName: String? = null,
    ): JsonNode {
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_JSON
            asUser?.let { setBearerAuth(TestSecurityConfig.testToken(it)) }
        }
        val body = objectMapper.writeValueAsString(
            mapOf("query" to document, "variables" to variables, "operationName" to operationName)
        )
        val response = restTemplate.postForEntity("/graphql", HttpEntity(body, headers), String::class.java)
        return objectMapper.readTree(response.body)
    }

    /** Executes [document] and fails the test if the response contains errors. */
    fun executeOk(
        document: String,
        variables: Map<String, Any?> = emptyMap(),
        asUser: UUID? = null,
        operationName: String? = null,
    ): JsonNode {
        val result = execute(document, variables, asUser, operationName)
        val errors = result.path("errors")
        check(errors.isMissingNode || errors.isEmpty) { "Unexpected GraphQL errors: $errors" }
        return result.path("data")
    }
}
