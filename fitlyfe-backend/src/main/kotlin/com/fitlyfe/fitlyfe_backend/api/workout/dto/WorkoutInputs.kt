package com.fitlyfe.fitlyfe_backend.api.workout.dto

data class LogWorkoutSessionInput(
    val clientId: String? = null,
    val startedAt: String,
    val endedAt: String,
    val workoutType: String? = null,
    val caloriesBurned: Int? = null,
    val notes: String? = null,
    val exercises: List<LoggedExerciseInput>,
)

data class LoggedExerciseInput(
    val name: String,
    val notes: String? = null,
    val sets: List<LoggedSetInput>,
)

data class LoggedSetInput(
    val reps: Int? = null,
    val weightKg: Double? = null,
    val durationSeconds: Int? = null,
    val distanceMeters: Double? = null,
)
