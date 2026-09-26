package com.fitlyfe.fitlyfe_backend.api.workout.controller

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import com.fitlyfe.fitlyfe_backend.api.workout.dto.LogWorkoutSessionInput
import com.fitlyfe.fitlyfe_backend.api.workout.entity.*
import com.fitlyfe.fitlyfe_backend.api.workout.service.WorkoutService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.BatchMapping
import org.springframework.graphql.data.method.annotation.MutationMapping
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.SchemaMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.time.LocalDateTime
import java.time.ZoneOffset
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

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun logWorkoutSession(
        @Argument input: LogWorkoutSessionInput,
        @AuthenticationPrincipal jwt: Jwt,
    ): WorkoutSessionEntity {
        val user = getUserFromJwt(jwt)
        return workoutService.logWorkoutSession(user, input)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun deleteWorkoutSession(@Argument id: String, @AuthenticationPrincipal jwt: Jwt): Boolean {
        val user = getUserFromJwt(jwt)
        workoutService.deleteWorkoutSession(user, UUID.fromString(id))
        return true
    }

    // Timestamps are stored as UTC without a zone; expose them with an explicit
    // offset so clients don't read them as local time
    @SchemaMapping(typeName = "WorkoutSession", field = "startedAt")
    fun startedAt(session: WorkoutSessionEntity): String? = session.startedAt?.toUtcString()

    @SchemaMapping(typeName = "WorkoutSession", field = "endedAt")
    fun endedAt(session: WorkoutSessionEntity): String? = session.endedAt?.toUtcString()

    // Batched so a list of sessions loads its exercises (and their sets) in one query per level
    @BatchMapping(typeName = "WorkoutSession", field = "exercises")
    fun getExercises(sessions: List<WorkoutSessionEntity>): List<List<WorkoutExerciseEntity>> {
        return workoutService.getExercisesForSessions(sessions)
    }

    @BatchMapping(typeName = "WorkoutExercise", field = "sets")
    fun getSets(workoutExercises: List<WorkoutExerciseEntity>): List<List<ExerciseSetEntity>> {
        return workoutService.getSetsForExercises(workoutExercises)
    }

    private fun LocalDateTime.toUtcString() = atOffset(ZoneOffset.UTC).toString()

    private fun getUserFromJwt(jwt: Jwt): UserEntity =
        userService.resolveUser(UUID.fromString(jwt.subject), jwt.getClaimAsString("email"))
}
