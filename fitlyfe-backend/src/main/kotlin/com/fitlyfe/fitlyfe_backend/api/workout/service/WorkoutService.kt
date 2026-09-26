package com.fitlyfe.fitlyfe_backend.api.workout.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseSetEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import com.fitlyfe.fitlyfe_backend.api.workout.repository.ExerciseSetRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutExerciseRepository
import com.fitlyfe.fitlyfe_backend.api.workout.repository.WorkoutSessionRepository
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service

@Service
class WorkoutService(
    private val workoutSessionRepository: WorkoutSessionRepository,
    private val workoutExerciseRepository: WorkoutExerciseRepository,
    private val exerciseSetRepository: ExerciseSetRepository
) {
    fun getWorkoutSessions(user: UserEntity, limit: Int): List<WorkoutSessionEntity> {
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
}
