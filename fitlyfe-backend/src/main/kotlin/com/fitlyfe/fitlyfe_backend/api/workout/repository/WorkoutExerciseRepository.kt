package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutExerciseEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import org.springframework.data.jpa.repository.EntityGraph
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface WorkoutExerciseRepository : JpaRepository<WorkoutExerciseEntity, UUID> {
    fun findBySessionOrderByOrderIndexAsc(session: WorkoutSessionEntity): List<WorkoutExerciseEntity>

    // Fetches the catalog exercise too, since the API almost always returns its name
    @EntityGraph(attributePaths = ["exercise"])
    fun findBySessionIdInOrderByOrderIndexAsc(sessionIds: Collection<UUID>): List<WorkoutExerciseEntity>

    fun findBySession(session: WorkoutSessionEntity): List<WorkoutExerciseEntity>
}
