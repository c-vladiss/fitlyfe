package com.fitlyfe.fitlyfe_backend.api.workout.entity

import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "exercises")
data class ExerciseEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(unique = true)
    val name: String,

    @Column(name = "muscle_group")
    val muscleGroup: String? = null,

    val equipment: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
