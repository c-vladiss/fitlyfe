package com.fitlyfe.fitlyfe_backend.api.workout.controller

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import com.fitlyfe.fitlyfe_backend.api.workout.entity.*
import com.fitlyfe.fitlyfe_backend.api.workout.service.WorkoutService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.BatchMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.util.UUID

@Controller
class WorkoutGraphQLController(
    private val workoutService: WorkoutService,
    private val userService: UserService
) {

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun workoutSessions(@Argument limit: Int?, @AuthenticationPrincipal jwt: Jwt): List<WorkoutSessionEntity> {
        val user = getUserFromJwt(jwt)
        return workoutService.getWorkoutSessions(user, limit ?: 10)
    }

    // Batched so a list of sessions loads its exercises (and their sets) in one query per level
    @BatchMapping(typeName = "WorkoutSession", field = "exercises")
    fun getExercises(sessions: List<WorkoutSessionEntity>): List<List<WorkoutExerciseEntity>> {
        return workoutService.getExercisesForSessions(sessions)
    }

    @BatchMapping(typeName = "WorkoutExercise", field = "sets")
    fun getSets(workoutExercises: List<WorkoutExerciseEntity>): List<List<ExerciseSetEntity>> {
        return workoutService.getSetsForExercises(workoutExercises)
    }

    private fun getUserFromJwt(jwt: Jwt): UserEntity =
        userService.resolveUser(UUID.fromString(jwt.subject), jwt.getClaimAsString("email"))
}
