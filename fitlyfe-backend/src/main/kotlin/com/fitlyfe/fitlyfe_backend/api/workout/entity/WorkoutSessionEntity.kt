package com.fitlyfe.fitlyfe_backend.api.workout.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "workout_sessions")
data class WorkoutSessionEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    @Column(name = "started_at")
    val startedAt: LocalDateTime? = null,

    @Column(name = "ended_at")
    val endedAt: LocalDateTime? = null,

    @Column(name = "duration_seconds")
    val durationSeconds: Int? = null,

    @Column(name = "workout_type")
    val workoutType: String? = null,

    @Column(name = "calories_burned")
    val caloriesBurned: Int? = null,

    val notes: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now()
)
