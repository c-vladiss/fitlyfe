package com.fitlyfe.fitlyfe_backend.api.user.controller

import com.fitlyfe.fitlyfe_backend.api.auth.controller.UserProfileData
import com.fitlyfe.fitlyfe_backend.api.auth.controller.toProfileData
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserGoalsEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.MutationMapping
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.time.LocalDate
import java.util.UUID

@Controller
class UserGraphQLController(
    private val userService: UserService
) {
    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun updateUserProfile(
        @Argument input: UpdateUserProfileInput,
        @AuthenticationPrincipal jwt: Jwt,
    ): UserProfileData {
        val supabaseId = UUID.fromString(jwt.subject)
        val user = userService.findBySupabaseId(supabaseId)
        val profile = userService.upsertProfile(
            userId = user.id,
            displayName = input.displayName,
            heightCm = input.heightCm,
            weightKg = input.weightKg,
            dateOfBirth = input.dateOfBirth?.let { LocalDate.parse(it) },
            goal = input.goal,
        )
        return profile.toProfileData()
    }

    // ── User Goals ──────────────────────────────────────────────────────

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun userGoals(@AuthenticationPrincipal jwt: Jwt): UserGoalsEntity {
        val supabaseId = UUID.fromString(jwt.subject)
        val user = userService.findBySupabaseId(supabaseId)
        return userService.getOrCreateGoals(user)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun updateUserGoals(
        @Argument dailyCalories: Int?,
        @Argument dailyProteinG: Double?,
        @Argument dailyCarbsG: Double?,
        @Argument dailyFatG: Double?,
        @Argument goalWeightKg: Double?,
        @AuthenticationPrincipal jwt: Jwt
    ): UserGoalsEntity {
        val supabaseId = UUID.fromString(jwt.subject)
        val user = userService.findBySupabaseId(supabaseId)
        return userService.updateGoals(
            user = user,
            dailyCalories = dailyCalories,
            dailyProteinG = dailyProteinG,
            dailyCarbsG = dailyCarbsG,
            dailyFatG = dailyFatG,
            goalWeightKg = goalWeightKg
        )
    }
}

data class UpdateUserProfileInput(
    val displayName: String? = null,
    val heightCm: Double? = null,
    val weightKg: Double? = null,
    val dateOfBirth: String? = null,
    val goal: String? = null,
)
