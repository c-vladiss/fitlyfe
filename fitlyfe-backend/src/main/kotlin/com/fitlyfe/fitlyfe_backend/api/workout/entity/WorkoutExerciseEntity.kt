package com.fitlyfe.fitlyfe_backend.api.workout.entity

import jakarta.persistence.*
import java.util.UUID

@Entity
@Table(name = "workout_exercises")
data class WorkoutExerciseEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id")
    val session: WorkoutSessionEntity,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id")
    val exercise: ExerciseEntity,

    @Column(name = "order_index")
    val orderIndex: Int? = null,

    val notes: String? = null
)
