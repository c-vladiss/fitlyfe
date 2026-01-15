package com.fitlyfe.fitlyfe_backend.api.workout.entity

import jakarta.persistence.*
import java.util.UUID

@Entity
@Table(name = "exercise_sets")
data class ExerciseSetEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_exercise_id")
    val workoutExercise: WorkoutExerciseEntity,

    @Column(name = "set_number")
    val setNumber: Int? = null,

    val reps: Int? = null,

    @Column(name = "weight_kg")
    val weightKg: Double? = null,

    @Column(name = "duration_seconds")
    val durationSeconds: Int? = null,

    @Column(name = "distance_meters")
    val distanceMeters: Double? = null
)
