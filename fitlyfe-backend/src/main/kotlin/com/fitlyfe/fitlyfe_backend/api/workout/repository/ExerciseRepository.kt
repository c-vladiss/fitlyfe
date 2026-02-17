package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.workout.entity.ExerciseEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface ExerciseRepository : JpaRepository<ExerciseEntity, UUID>
