package com.fitlyfe.fitlyfe_backend.api.workout

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseSetRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutSessionRepository
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import com.fitlyfe.fitlyfe_backend.common.GraphQLTestClient
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import java.util.UUID

class WorkoutGraphQLTest : AbstractIntegrationTest() {

    @Autowired lateinit var restTemplate: TestRestTemplate
    @Autowired lateinit var objectMapper: ObjectMapper
    @Autowired lateinit var workoutSessionRepository: WorkoutSessionRepository
    @Autowired lateinit var workoutExerciseRepository: WorkoutExerciseRepository
    @Autowired lateinit var exerciseSetRepository: ExerciseSetRepository
    @Autowired lateinit var exerciseRepository: ExerciseRepository

    private lateinit var client: GraphQLTestClient

    @BeforeEach
    fun setUp() {
        client = GraphQLTestClient(restTemplate, objectMapper)
    }

    private val sessionFields = """
        id startedAt endedAt durationSeconds workoutType caloriesBurned notes
        exercises { orderIndex notes exercise { id name } sets { setNumber reps weightKg durationSeconds distanceMeters } }
    """

    private val logMutation = """
        mutation(${'$'}input: LogWorkoutSessionInput!) { logWorkoutSession(input: ${'$'}input) { $sessionFields } }
    """.trimIndent()

    private fun set(reps: Int? = null, weightKg: Double? = null, durationSeconds: Int? = null, distanceMeters: Double? = null) =
        mapOf("reps" to reps, "weightKg" to weightKg, "durationSeconds" to durationSeconds, "distanceMeters" to distanceMeters)

    private fun exercise(name: String, vararg sets: Map<String, Any?>, notes: String? = null) =
        mapOf("name" to name, "notes" to notes, "sets" to sets.toList())

    private fun input(
        vararg exercises: Map<String, Any?>,
        startedAt: String = "2025-05-01T08:00:00Z",
        endedAt: String = "2025-05-01T09:00:00Z",
        workoutType: String? = "Push Day",
        caloriesBurned: Int? = null,
        clientId: String? = null,
    ) = mapOf(
        "clientId" to clientId,
        "startedAt" to startedAt,
        "endedAt" to endedAt,
        "workoutType" to workoutType,
        "caloriesBurned" to caloriesBurned,
        "notes" to null,
        "exercises" to exercises.toList(),
    )

    private fun log(user: UUID, input: Map<String, Any?>): JsonNode =
        client.executeOk(logMutation, mapOf("input" to input), asUser = user).path("logWorkoutSession")

    private fun sessions(user: UUID): JsonNode =
        client.executeOk("{ workoutSessions(limit: 100) { $sessionFields } }", asUser = user).path("workoutSessions")

    private fun JsonNode.classification() = path("errors").path(0).path("extensions").path("classification").asText()

    // ── Logging ─────────────────────────────────────────────────────────

    @Test
    fun `logs a session with ordered exercises and numbered sets`() {
        val user = UUID.randomUUID()
        val session = log(
            user,
            input(
                exercise("Bench Press", set(reps = 10, weightKg = 60.0), set(reps = 8, weightKg = 70.0), notes = "felt strong"),
                exercise("Plank", set(durationSeconds = 60)),
                exercise("Rowing", set(distanceMeters = 2000.0, durationSeconds = 480)),
                caloriesBurned = 350,
            ),
        )

        assertEquals("Push Day", session.path("workoutType").asText())
        assertEquals(3600, session.path("durationSeconds").asInt())
        assertEquals(350, session.path("caloriesBurned").asInt())

        val exercises = session.path("exercises")
        assertEquals(listOf("Bench Press", "Plank", "Rowing"), exercises.map { it.path("exercise").path("name").asText() })
        assertEquals(listOf(0, 1, 2), exercises.map { it.path("orderIndex").asInt() })
        assertEquals("felt strong", exercises[0].path("notes").asText())

        val bench = exercises[0].path("sets")
        assertEquals(listOf(1, 2), bench.map { it.path("setNumber").asInt() })
        assertEquals(listOf(10, 8), bench.map { it.path("reps").asInt() })
        assertEquals(listOf(60.0, 70.0), bench.map { it.path("weightKg").asDouble() })
        assertEquals(60, exercises[1].path("sets")[0].path("durationSeconds").asInt())
        assertTrue(exercises[1].path("sets")[0].path("reps").isNull)
        assertEquals(2000.0, exercises[2].path("sets")[0].path("distanceMeters").asDouble())

        // What the mutation returned is what was stored
        assertEquals(session, sessions(user)[0])
    }

    @Test
    fun `timestamps are normalised to UTC`() {
        val user = UUID.randomUUID()
        val session = log(
            user,
            input(
                exercise("Squat", set(reps = 5)),
                startedAt = "2025-05-01T10:00:00+02:00",
                endedAt = "2025-05-01T10:45:30+02:00",
            ),
        )
        assertEquals("2025-05-01T08:00Z", session.path("startedAt").asText())
        assertEquals("2025-05-01T08:45:30Z", session.path("endedAt").asText())
        assertEquals(45 * 60 + 30, session.path("durationSeconds").asInt())
    }

    @Test
    fun `sessions are listed newest first and only for their owner`() {
        val user = UUID.randomUUID()
        log(user, input(exercise("Squat", set(reps = 5)), startedAt = "2025-05-01T08:00:00Z", endedAt = "2025-05-01T09:00:00Z", workoutType = "older"))
        log(user, input(exercise("Squat", set(reps = 5)), startedAt = "2025-05-03T08:00:00Z", endedAt = "2025-05-03T09:00:00Z", workoutType = "newer"))

        assertEquals(listOf("newer", "older"), sessions(user).map { it.path("workoutType").asText() })
        assertEquals(0, sessions(UUID.randomUUID()).size())
    }

    @Test
    fun `exercise names are matched to the catalog ignoring case and whitespace`() {
        val name = "Deadlift ${UUID.randomUUID()}"
        val first = log(UUID.randomUUID(), input(exercise(name, set(reps = 5)), exercise("  ${name.uppercase()} ", set(reps = 3))))
        val second = log(UUID.randomUUID(), input(exercise(name.lowercase(), set(reps = 1))))

        val ids = (first.path("exercises").toList() + second.path("exercises").toList())
            .map { it.path("exercise").path("id").asText() }
            .toSet()
        assertEquals(1, ids.size, "all three entries should share one catalog exercise")
        // The catalog keeps the spelling it was first created with
        assertEquals(name, second.path("exercises")[0].path("exercise").path("name").asText())
        assertEquals(1, exerciseRepository.findAll().count { it.name.equals(name, ignoreCase = true) })
    }

    @Test
    fun `retrying with the same clientId does not create a duplicate`() {
        val user = UUID.randomUUID()
        val clientId = UUID.randomUUID().toString()

        val first = log(user, input(exercise("Squat", set(reps = 5)), clientId = clientId))
        val retry = log(user, input(exercise("Squat", set(reps = 5)), clientId = clientId))

        assertEquals(first, retry)
        assertEquals(1, sessions(user).size())

        // The key is scoped per user
        val otherUser = UUID.randomUUID()
        val other = log(otherUser, input(exercise("Squat", set(reps = 5)), clientId = clientId))
        assertTrue(other.path("id").asText() != first.path("id").asText())
        assertEquals(1, sessions(otherUser).size())
    }

    // ── Validation ──────────────────────────────────────────────────────

    @Test
    fun `invalid workouts are rejected with BAD_REQUEST and nothing is saved`() {
        val user = UUID.randomUUID()
        val invalidInputs = mapOf(
            "no exercises" to input(),
            "ends before it starts" to input(exercise("Squat", set(reps = 5)), startedAt = "2025-05-01T09:00:00Z", endedAt = "2025-05-01T08:00:00Z"),
            "blank exercise name" to input(exercise("   ", set(reps = 5))),
            "negative reps" to input(exercise("Squat", set(reps = -1))),
            "negative weight" to input(exercise("Squat", set(reps = 5, weightKg = -20.0))),
            "negative calories" to input(exercise("Squat", set(reps = 5)), caloriesBurned = -5),
            "malformed timestamp" to input(exercise("Squat", set(reps = 5)), startedAt = "yesterday"),
            "malformed clientId" to input(exercise("Squat", set(reps = 5)), clientId = "not-a-uuid"),
            "too many sets" to input(exercise("Squat", *Array(101) { set(reps = 1) })),
        )

        invalidInputs.forEach { (case, invalid) ->
            val result = client.execute(logMutation, mapOf("input" to invalid), asUser = user)
            assertEquals("BAD_REQUEST", result.classification(), "case '$case': ${result.path("errors")}")
        }
        assertEquals(0, sessions(user).size())
    }

    @Test
    fun `workoutSessions rejects an out-of-range limit`() {
        val result = client.execute("{ workoutSessions(limit: 0) { id } }", asUser = UUID.randomUUID())
        assertEquals("BAD_REQUEST", result.classification())
    }

    @Test
    fun `logging requires authentication`() {
        val result = client.execute(logMutation, mapOf("input" to input(exercise("Squat", set(reps = 5)))))
        assertEquals("FORBIDDEN", result.classification())
    }

    // ── Deleting ────────────────────────────────────────────────────────

    private val deleteMutation = "mutation(\$id: ID!) { deleteWorkoutSession(id: \$id) }"

    @Test
    fun `deleting a session removes its exercises and sets but keeps the catalog`() {
        val user = UUID.randomUUID()
        val keep = log(user, input(exercise("Squat", set(reps = 5)), workoutType = "keep"))
        val remove = log(user, input(exercise("Squat", set(reps = 5), set(reps = 5)), exercise("Lunge", set(reps = 8)), workoutType = "remove"))
        val removeId = UUID.fromString(remove.path("id").asText())
        val exerciseCountBefore = exerciseRepository.count()

        val result = client.executeOk(deleteMutation, mapOf("id" to removeId.toString()), asUser = user)

        assertTrue(result.path("deleteWorkoutSession").asBoolean())
        assertFalse(workoutSessionRepository.existsById(removeId))
        assertEquals(listOf("keep"), sessions(user).map { it.path("workoutType").asText() })
        assertEquals(1, sessions(user)[0].path("exercises")[0].path("sets").size())
        assertEquals(exerciseCountBefore, exerciseRepository.count())
        assertEquals(keep, sessions(user)[0])
    }

    @Test
    fun `cannot delete another user's session`() {
        val owner = UUID.randomUUID()
        val session = log(owner, input(exercise("Squat", set(reps = 5))))

        val result = client.execute(deleteMutation, mapOf("id" to session.path("id").asText()), asUser = UUID.randomUUID())

        assertEquals("BAD_REQUEST", result.classification())
        assertEquals(1, sessions(owner).size())
    }

    @Test
    fun `deleting an unknown session is NOT_FOUND`() {
        val result = client.execute(deleteMutation, mapOf("id" to UUID.randomUUID().toString()), asUser = UUID.randomUUID())
        assertEquals("NOT_FOUND", result.classification())
        assertNull(result.path("data").path("deleteWorkoutSession").textValue())
    }
}
