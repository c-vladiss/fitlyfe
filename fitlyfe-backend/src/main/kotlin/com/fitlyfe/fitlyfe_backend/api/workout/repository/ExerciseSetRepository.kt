package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseSetEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface ExerciseSetRepository : JpaRepository<ExerciseSetEntity, UUID> {
    fun findByWorkoutExerciseOrderBySetNumberAsc(workoutExercise: WorkoutExerciseEntity): List<ExerciseSetEntity>
}
