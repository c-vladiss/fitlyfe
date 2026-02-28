package com.fitlyfe.fitlyfe_backend.api.nutrition.controller

import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.MealTypeInput
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntryEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.UserMealTypeEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.service.NutritionService
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.MutationMapping
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.SchemaMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.time.LocalDate
import java.util.UUID

@Controller
class NutritionGraphQLController(
    private val nutritionService: NutritionService,
    private val userService: UserService
) {

    // ── Queries ─────────────────────────────────────────────────────────

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun dailyNutrition(@Argument date: String, @AuthenticationPrincipal jwt: Jwt): DailyNutritionEntity? {
        val user = getUserFromJwt(jwt)
        return nutritionService.getDailyNutrition(user, LocalDate.parse(date))
    }

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun weeklyNutrition(
        @Argument startDate: String,
        @Argument endDate: String,
        @AuthenticationPrincipal jwt: Jwt
    ): List<DailyNutritionEntity> {
        val user = getUserFromJwt(jwt)
        return nutritionService.getWeeklyNutrition(user, LocalDate.parse(startDate), LocalDate.parse(endDate))
    }

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun userMealTypes(@AuthenticationPrincipal jwt: Jwt): List<UserMealTypeEntity> {
        val user = getUserFromJwt(jwt)
        return nutritionService.getOrInitMealTypes(user)
    }

    // ── Schema Mappings ─────────────────────────────────────────────────

    @SchemaMapping(typeName = "DailyNutrition", field = "meals")
    fun getMeals(dailyNutrition: DailyNutritionEntity): List<MealEntity> {
        return nutritionService.getMealsForDailyNutrition(dailyNutrition)
    }

    @SchemaMapping(typeName = "Meal", field = "entries")
    fun getEntries(meal: MealEntity): List<MealEntryEntity> {
        return nutritionService.getEntriesForMeal(meal)
    }

    // ── Template Management Mutations ───────────────────────────────────

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun createUserMealTypes(
        @Argument types: List<MealTypeInput>,
        @AuthenticationPrincipal jwt: Jwt
    ): List<UserMealTypeEntity> {
        val user = getUserFromJwt(jwt)
        return nutritionService.createUserMealTypes(user, types.map { it.name to it.sortOrder })
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun addUserMealType(
        @Argument name: String,
        @Argument sortOrder: Int,
        @AuthenticationPrincipal jwt: Jwt
    ): UserMealTypeEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.addUserMealType(user, name, sortOrder)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun updateUserMealType(
        @Argument id: String,
        @Argument name: String?,
        @Argument sortOrder: Int?,
        @AuthenticationPrincipal jwt: Jwt
    ): UserMealTypeEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.updateUserMealType(user, UUID.fromString(id), name, sortOrder)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun deleteUserMealType(
        @Argument id: String,
        @AuthenticationPrincipal jwt: Jwt
    ): Boolean {
        val user = getUserFromJwt(jwt)
        nutritionService.deleteUserMealType(user, UUID.fromString(id))
        return true
    }

    // ── Per-Day Meal Management Mutations ────────────────────────────────

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun addMealToDay(
        @Argument date: String,
        @Argument mealType: String,
        @AuthenticationPrincipal jwt: Jwt
    ): MealEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.addMealToDay(user, LocalDate.parse(date), mealType)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun renameMealOnDay(
        @Argument mealId: String,
        @Argument newName: String,
        @AuthenticationPrincipal jwt: Jwt
    ): MealEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.renameMealOnDay(user, UUID.fromString(mealId), newName)
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun deleteMealFromDay(
        @Argument mealId: String,
        @AuthenticationPrincipal jwt: Jwt
    ): Boolean {
        val user = getUserFromJwt(jwt)
        nutritionService.deleteMealFromDay(user, UUID.fromString(mealId))
        return true
    }

    // ── Meal Entry CRUD Mutations ───────────────────────────────────────

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun addMealEntry(
        @Argument date: String,
        @Argument mealType: String,
        @Argument foodEntryId: String,
        @Argument quantityG: Double,
        @AuthenticationPrincipal jwt: Jwt
    ): MealEntryEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.addMealEntry(
            user, LocalDate.parse(date), mealType, UUID.fromString(foodEntryId), quantityG
        )
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun updateMealEntry(
        @Argument entryId: String,
        @Argument quantityG: Double?,
        @Argument foodEntryId: String?,
        @AuthenticationPrincipal jwt: Jwt
    ): MealEntryEntity {
        val user = getUserFromJwt(jwt)
        return nutritionService.updateMealEntry(
            user, UUID.fromString(entryId), quantityG, foodEntryId?.let { UUID.fromString(it) }
        )
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun deleteMealEntry(
        @Argument entryId: String,
        @AuthenticationPrincipal jwt: Jwt
    ): Boolean {
        val user = getUserFromJwt(jwt)
        nutritionService.deleteMealEntry(user, UUID.fromString(entryId))
        return true
    }

    // ── Helper ──────────────────────────────────────────────────────────

    private fun getUserFromJwt(jwt: Jwt): UserEntity {
        val supabaseId = jwt.getClaimAsString("sub")
        val email = jwt.getClaimAsString("email")
        return userService.getOrCreate(supabaseId, email)
    }
}
