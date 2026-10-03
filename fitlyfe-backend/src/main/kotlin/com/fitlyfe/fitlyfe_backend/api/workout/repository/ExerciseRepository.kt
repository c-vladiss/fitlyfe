package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface ExerciseRepository : JpaRepository<ExerciseEntity, UUID> {
    // lower() matches the uq_exercises_name_lower index
    @Query("select e from ExerciseEntity e where lower(e.name) = lower(:name)")
    fun findByNameIgnoreCase(@Param("name") name: String): ExerciseEntity?
}
