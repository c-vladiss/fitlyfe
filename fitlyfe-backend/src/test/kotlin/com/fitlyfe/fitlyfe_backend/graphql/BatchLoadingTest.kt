package com.fitlyfe.fitlyfe_backend.graphql

import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseSetEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseSetRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutSessionRepository
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import com.fitlyfe.fitlyfe_backend.common.GraphQLTestClient
import jakarta.persistence.EntityManagerFactory
import org.hibernate.SessionFactory
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

/**
 * Nested list fields are resolved with @BatchMapping, so the number of SQL
 * statements for a request must not grow with the number of parent rows.
 */
class BatchLoadingTest : AbstractIntegrationTest() {

    @Autowired lateinit var restTemplate: TestRestTemplate
    @Autowired lateinit var objectMapper: ObjectMapper
    @Autowired lateinit var entityManagerFactory: EntityManagerFactory
    @Autowired lateinit var foodEntryRepository: FoodEntryRepository
    @Autowired lateinit var userService: UserService
    @Autowired lateinit var exerciseRepository: ExerciseRepository
    @Autowired lateinit var workoutSessionRepository: WorkoutSessionRepository
    @Autowired lateinit var workoutExerciseRepository: WorkoutExerciseRepository
    @Autowired lateinit var exerciseSetRepository: ExerciseSetRepository

    private lateinit var client: GraphQLTestClient

    private val statistics get() = entityManagerFactory.unwrap(SessionFactory::class.java).statistics

    @BeforeEach
    fun setUp() {
        client = GraphQLTestClient(restTemplate, objectMapper)
    }

    private fun statementsFor(block: () -> Unit): Long {
        statistics.clear()
        block()
        return statistics.prepareStatementCount
    }

    // ── Nutrition ───────────────────────────────────────────────────────

    private val weeklyQuery = """
        query(${'$'}start: String!, ${'$'}end: String!) {
          weeklyNutrition(startDate: ${'$'}start, endDate: ${'$'}end) {
            date
            meals { id mealType entries { id quantityG } }
          }
        }
    """.trimIndent()

    private fun logFood(user: UUID, date: LocalDate, mealType: String, foodId: UUID, grams: Double) {
        client.executeOk(
            """
            mutation(${'$'}date: String!, ${'$'}meal: String!, ${'$'}food: ID!, ${'$'}g: Float!) {
              addMealEntry(date: ${'$'}date, mealType: ${'$'}meal, foodEntryId: ${'$'}food, quantityG: ${'$'}g) { entry { id } }
            }
            """.trimIndent(),
            mapOf("date" to date.toString(), "meal" to mealType, "food" to foodId.toString(), "g" to grams),
            asUser = user,
        )
    }

    @Test
    fun `weeklyNutrition returns each day's own meals and entries`() {
        val user = UUID.randomUUID()
        val food = foodEntryRepository.findAll().first().id
        val monday = LocalDate.of(2025, 3, 3)
        logFood(user, monday, "Breakfast", food, 100.0)
        logFood(user, monday, "Breakfast", food, 50.0)
        logFood(user, monday.plusDays(2), "Dinner", food, 250.0)

        val days = client.executeOk(
            weeklyQuery, mapOf("start" to monday.toString(), "end" to monday.plusDays(6).toString()), asUser = user,
        ).path("weeklyNutrition")

        val byDate = days.associateBy { it.path("date").asText() }
        assertEquals(setOf(monday.toString(), monday.plusDays(2).toString()), byDate.keys)

        fun entriesOf(date: LocalDate, meal: String) = byDate.getValue(date.toString()).path("meals")
            .first { it.path("mealType").asText() == meal }
            .path("entries").map { it.path("quantityG").asDouble() }.sorted()

        assertEquals(listOf(50.0, 100.0), entriesOf(monday, "Breakfast"))
        assertEquals(emptyList<Double>(), entriesOf(monday, "Dinner"))
        assertEquals(listOf(250.0), entriesOf(monday.plusDays(2), "Dinner"))
        assertEquals(emptyList<Double>(), entriesOf(monday.plusDays(2), "Breakfast"))
    }

    @Test
    fun `weeklyNutrition statement count does not grow with the number of days`() {
        val user = UUID.randomUUID()
        val food = foodEntryRepository.findAll().first().id
        val start = LocalDate.of(2025, 4, 7)
        (0L until 7L).forEach { day ->
            listOf("Breakfast", "Lunch", "Dinner").forEach { meal ->
                logFood(user, start.plusDays(day), meal, food, 100.0)
            }
        }

        val oneDay = statementsFor {
            client.executeOk(weeklyQuery, mapOf("start" to start.toString(), "end" to start.toString()), asUser = user)
        }
        val sevenDays = statementsFor {
            val days = client.executeOk(
                weeklyQuery, mapOf("start" to start.toString(), "end" to start.plusDays(6).toString()), asUser = user,
            ).path("weeklyNutrition")
            assertEquals(7, days.size())
            assertTrue(days.all { d -> d.path("meals").all { it.path("entries").size() == 1 } })
        }

        assertEquals(oneDay, sevenDays, "7 days ($sevenDays statements) should cost the same as 1 day ($oneDay)")
        assertTrue(sevenDays <= 5, "expected user + days + meals + entries lookups, got $sevenDays statements")
    }

    // ── Workouts ────────────────────────────────────────────────────────

    private val sessionsQuery = """
        { workoutSessions(limit: 50) { id exercises { orderIndex sets { setNumber reps } } } }
    """.trimIndent()

    private fun seedWorkouts(supabaseId: UUID, sessionCount: Int) {
        val user = userService.syncUser(supabaseId, "$supabaseId@test.fitlyfe").first
        val exercises = (1..3).map {
            exerciseRepository.save(ExerciseEntity(name = "Exercise $it ${UUID.randomUUID()}"))
        }
        repeat(sessionCount) { s ->
            val session = workoutSessionRepository.save(
                WorkoutSessionEntity(user = user, startedAt = LocalDateTime.of(2025, 1, 1, 8, 0).plusDays(s.toLong()))
            )
            // Saved out of order to check ordering by orderIndex / setNumber
            exercises.withIndex().reversed().forEach { (i, exercise) ->
                val we = workoutExerciseRepository.save(
                    WorkoutExerciseEntity(session = session, exercise = exercise, orderIndex = i)
                )
                (3 downTo 1).forEach { n ->
                    exerciseSetRepository.save(ExerciseSetEntity(workoutExercise = we, setNumber = n, reps = 10 + n))
                }
            }
        }
    }

    @Test
    fun `workoutSessions nests exercises and sets in order`() {
        val user = UUID.randomUUID()
        seedWorkouts(user, sessionCount = 2)

        val sessions = client.executeOk(sessionsQuery, asUser = user).path("workoutSessions")

        assertEquals(2, sessions.size())
        sessions.forEach { session ->
            val exercises = session.path("exercises")
            assertEquals(listOf(0, 1, 2), exercises.map { it.path("orderIndex").asInt() })
            exercises.forEach { exercise ->
                assertEquals(listOf(1, 2, 3), exercise.path("sets").map { it.path("setNumber").asInt() })
                assertEquals(listOf(11, 12, 13), exercise.path("sets").map { it.path("reps").asInt() })
            }
        }
    }

    @Test
    fun `workoutSessions statement count does not grow with the number of sessions`() {
        val fewUser = UUID.randomUUID()
        val manyUser = UUID.randomUUID()
        seedWorkouts(fewUser, sessionCount = 1)
        seedWorkouts(manyUser, sessionCount = 6)

        val few = statementsFor { client.executeOk(sessionsQuery, asUser = fewUser) }
        val many = statementsFor {
            assertEquals(6, client.executeOk(sessionsQuery, asUser = manyUser).path("workoutSessions").size())
        }

        assertEquals(few, many, "6 sessions ($many statements) should cost the same as 1 session ($few)")
    }
}
