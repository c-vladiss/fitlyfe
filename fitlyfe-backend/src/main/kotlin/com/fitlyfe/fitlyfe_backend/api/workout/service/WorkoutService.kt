package com.fitlyfe.fitlyfe_backend.api.workout.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
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

    fun getExercisesForSession(session: WorkoutSessionEntity): List<WorkoutExerciseEntity> {
        return workoutExerciseRepository.findBySessionOrderByOrderIndexAsc(session)
    }

    fun getSetsForExercise(workoutExercise: WorkoutExerciseEntity) =
        exerciseSetRepository.findByWorkoutExerciseOrderBySetNumberAsc(workoutExercise)
}
