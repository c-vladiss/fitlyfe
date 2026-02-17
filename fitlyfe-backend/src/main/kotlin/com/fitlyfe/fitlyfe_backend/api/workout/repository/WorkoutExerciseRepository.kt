package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface WorkoutExerciseRepository : JpaRepository<WorkoutExerciseEntity, UUID> {
    fun findBySessionOrderByOrderIndexAsc(session: WorkoutSessionEntity): List<WorkoutExerciseEntity>
}
