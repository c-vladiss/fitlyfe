package com.fitlyfe.fitlyfe_backend.api.workout

import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import com.fitlyfe.fitlyfe_backend.common.GraphQLTestClient
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import java.io.File
import java.util.UUID

/**
 * Runs the Flutter app's own workout operations (lib/graphql/operations/workout.graphql)
 * against the backend, with variables shaped exactly as the generated Dart code sends
 * them, so a schema change that breaks the app fails here.
 */
class FrontendWorkoutOperationsContractTest : AbstractIntegrationTest() {

    @Autowired lateinit var restTemplate: TestRestTemplate
    @Autowired lateinit var objectMapper: ObjectMapper

    private val document = File("../fitlyfe_frontend/lib/graphql/operations/workout.graphql").readText()

    @Test
    fun `the app's workout operations work end to end`() {
        val client = GraphQLTestClient(restTemplate, objectMapper)
        val user = UUID.randomUUID()
        val clientId = UUID.randomUUID().toString()
        // Same JSON as Variables$Mutation$LogWorkoutSession(...).toJson() in Dart:
        // DateTime.toUtc().toIso8601String() timestamps, unset fields omitted
        val variables = objectMapper.readValue(
            """
            {"input":{"clientId":"$clientId","startedAt":"2025-05-01T08:00:00.000Z",
              "endedAt":"2025-05-01T09:00:00.000Z","workoutType":"Push Day",
              "exercises":[{"name":"Bench Press","sets":[{"reps":10,"weightKg":60.0},{"reps":8}]}]}}
            """.trimIndent(),
            Map::class.java,
        ).mapKeys { it.key as String }

        val logged = client.executeOk(document, variables, user, "LogWorkoutSession").path("logWorkoutSession")
        assertEquals("2025-05-01T08:00Z", logged.path("startedAt").asText())
        assertEquals("Bench Press", logged.path("exercises")[0].path("exercise").path("name").asText())
        assertEquals(listOf(10, 8), logged.path("exercises")[0].path("sets").map { it.path("reps").asInt() })

        // The app retries with the same clientId after a network error
        val retried = client.executeOk(document, variables, user, "LogWorkoutSession").path("logWorkoutSession")
        assertEquals(logged, retried)

        val listed = client.executeOk(document, mapOf("limit" to 50), user, "WorkoutSessions").path("workoutSessions")
        assertEquals(listOf(logged), listed.toList())

        val deleted = client.executeOk(document, mapOf("id" to logged.path("id").asText()), user, "DeleteWorkoutSession")
        assertTrue(deleted.path("deleteWorkoutSession").asBoolean())
        assertEquals(0, client.executeOk(document, mapOf("limit" to 50), user, "WorkoutSessions").path("workoutSessions").size())
    }
}
