package com.fitlyfe.fitlyfe_backend.api.workout.repository

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.workout.entity.WorkoutSessionEntity
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface WorkoutSessionRepository : JpaRepository<WorkoutSessionEntity, UUID> {
    fun findByUserOrderByStartedAtDesc(user: UserEntity, pageable: Pageable): List<WorkoutSessionEntity>
}
