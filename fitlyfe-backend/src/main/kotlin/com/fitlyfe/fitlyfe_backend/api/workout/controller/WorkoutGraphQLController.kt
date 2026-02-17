package com.fitlyfe.fitlyfe_backend.api.workout.controller

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import com.fitlyfe.fitlyfe_backend.api.workout.entity.*
import com.fitlyfe.fitlyfe_backend.api.workout.service.WorkoutService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.SchemaMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller

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

    @SchemaMapping(typeName = "WorkoutSession", field = "exercises")
    fun getExercises(session: WorkoutSessionEntity): List<WorkoutExerciseEntity> {
        return workoutService.getExercisesForSession(session)
    }

    @SchemaMapping(typeName = "WorkoutExercise", field = "sets")
    fun getSets(workoutExercise: WorkoutExerciseEntity): List<ExerciseSetEntity> {
        return workoutService.getSetsForExercise(workoutExercise)
    }

    private fun getUserFromJwt(jwt: Jwt): UserEntity {
        val supabaseId = jwt.getClaimAsString("sub")
        val email = jwt.getClaimAsString("email")
        return userService.getOrCreate(supabaseId, email)
    }
}
