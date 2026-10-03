package com.fitlyfe.fitlyfe_backend.api.workout.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.workout.dto.LogWorkoutSessionInput
import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseSetEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseSetRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutSessionRepository
import jakarta.persistence.EntityNotFoundException
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Duration
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeParseException
import java.util.UUID

@Service
class WorkoutService(
    private val workoutSessionRepository: WorkoutSessionRepository,
    private val workoutExerciseRepository: WorkoutExerciseRepository,
    private val exerciseSetRepository: ExerciseSetRepository,
    private val exerciseRepository: ExerciseRepository,
) {
    companion object {
        const val MAX_SESSIONS_PER_PAGE = 100
        const val MAX_EXERCISES_PER_SESSION = 50
        const val MAX_SETS_PER_EXERCISE = 100
        const val MAX_NAME_LENGTH = 255
    }

    fun getWorkoutSessions(user: UserEntity, limit: Int): List<WorkoutSessionEntity> {
        require(limit in 1..MAX_SESSIONS_PER_PAGE) { "limit must be between 1 and $MAX_SESSIONS_PER_PAGE" }
        val pageable = PageRequest.of(0, limit)
        return workoutSessionRepository.findByUserOrderByStartedAtDesc(user, pageable)
    }

    /** Loads the exercises of several sessions in one query, returned in the order of [sessions]. */
    fun getExercisesForSessions(sessions: List<WorkoutSessionEntity>): List<List<WorkoutExerciseEntity>> {
        val bySession = workoutExerciseRepository.findBySessionIdInOrderByOrderIndexAsc(sessions.map { it.id })
            .groupBy { it.session.id }
        return sessions.map { bySession[it.id].orEmpty() }
    }

    /** Loads the sets of several workout exercises in one query, returned in the order of [exercises]. */
    fun getSetsForExercises(exercises: List<WorkoutExerciseEntity>): List<List<ExerciseSetEntity>> {
        val byExercise = exerciseSetRepository.findByWorkoutExerciseIdInOrderBySetNumberAsc(exercises.map { it.id })
            .groupBy { it.workoutExercise.id }
        return exercises.map { byExercise[it.id].orEmpty() }
    }

    /**
     * Saves a finished workout with its exercises and sets. Set numbers and
     * exercise order follow the order of the input lists.
     */
    @Transactional
    fun logWorkoutSession(user: UserEntity, input: LogWorkoutSessionInput): WorkoutSessionEntity {
        val clientId = input.clientId?.let { UUID.fromString(it) }
        // A retry of a request that already succeeded: return what was saved then
        clientId?.let { workoutSessionRepository.findByUserAndClientId(user, it) }?.let { return it }

        val startedAt = parseTimestamp(input.startedAt, "startedAt")
        val endedAt = parseTimestamp(input.endedAt, "endedAt")
        require(!endedAt.isBefore(startedAt)) { "endedAt must not be before startedAt" }
        require(input.exercises.isNotEmpty()) { "A workout needs at least one exercise" }
        require(input.exercises.size <= MAX_EXERCISES_PER_SESSION) {
            "A workout can have at most $MAX_EXERCISES_PER_SESSION exercises"
        }
        requireNonNegative(input.caloriesBurned, "caloriesBurned")
        input.exercises.forEach { exercise ->
            val name = exercise.name.trim()
            require(name.isNotEmpty()) { "Exercise name must not be blank" }
            require(name.length <= MAX_NAME_LENGTH) { "Exercise name is too long" }
            require(exercise.sets.size <= MAX_SETS_PER_EXERCISE) {
                "An exercise can have at most $MAX_SETS_PER_EXERCISE sets"
            }
            exercise.sets.forEach { set ->
                requireNonNegative(set.reps, "reps")
                requireNonNegative(set.weightKg, "weightKg")
                requireNonNegative(set.durationSeconds, "durationSeconds")
                requireNonNegative(set.distanceMeters, "distanceMeters")
            }
        }

        val session = workoutSessionRepository.save(
            WorkoutSessionEntity(
                user = user,
                startedAt = startedAt,
                endedAt = endedAt,
                durationSeconds = Duration.between(startedAt, endedAt).seconds.toInt(),
                workoutType = input.workoutType?.trim()?.take(50)?.ifEmpty { null },
                caloriesBurned = input.caloriesBurned,
                notes = input.notes,
                clientId = clientId,
            )
        )

        // The same exercise may appear twice in one input; resolve each name once
        val catalog = mutableMapOf<String, ExerciseEntity>()
        input.exercises.forEachIndexed { index, loggedExercise ->
            val name = loggedExercise.name.trim()
            val exercise = catalog.getOrPut(name.lowercase()) { findOrCreateExercise(name) }
            val workoutExercise = workoutExerciseRepository.save(
                WorkoutExerciseEntity(
                    session = session,
                    exercise = exercise,
                    orderIndex = index,
                    notes = loggedExercise.notes,
                )
            )
            exerciseSetRepository.saveAll(
                loggedExercise.sets.mapIndexed { setIndex, set ->
                    ExerciseSetEntity(
                        workoutExercise = workoutExercise,
                        setNumber = setIndex + 1,
                        reps = set.reps,
                        weightKg = set.weightKg,
                        durationSeconds = set.durationSeconds,
                        distanceMeters = set.distanceMeters,
                    )
                }
            )
        }
        return session
    }

    @Transactional
    fun deleteWorkoutSession(user: UserEntity, sessionId: UUID) {
        val session = workoutSessionRepository.findById(sessionId)
            .orElseThrow { EntityNotFoundException("Workout session not found: $sessionId") }
        if (session.user.id != user.id) {
            throw IllegalArgumentException("Workout session does not belong to user")
        }
        // The foreign keys have no ON DELETE CASCADE, so delete bottom-up
        val exercises = workoutExerciseRepository.findBySession(session)
        if (exercises.isNotEmpty()) {
            exerciseSetRepository.deleteByWorkoutExerciseIn(exercises)
            workoutExerciseRepository.deleteAll(exercises)
        }
        workoutSessionRepository.delete(session)
    }

    private fun findOrCreateExercise(name: String): ExerciseEntity =
        exerciseRepository.findByNameIgnoreCase(name)
            ?: exerciseRepository.save(ExerciseEntity(name = name))

    /** Parses an ISO-8601 timestamp into a UTC LocalDateTime (the columns have no time zone). */
    private fun parseTimestamp(value: String, field: String): LocalDateTime =
        try {
            OffsetDateTime.parse(value).withOffsetSameInstant(ZoneOffset.UTC).toLocalDateTime()
        } catch (_: DateTimeParseException) {
            try {
                LocalDateTime.parse(value)
            } catch (_: DateTimeParseException) {
                throw IllegalArgumentException("$field is not a valid ISO-8601 timestamp: $value")
            }
        }

    private fun requireNonNegative(value: Number?, field: String) {
        require(value == null || value.toDouble() >= 0) { "$field must not be negative" }
    }
}
