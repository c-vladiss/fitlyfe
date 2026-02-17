package com.fitlyfe.fitlyfe_backend.api.nutrition.controller

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealFoodEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.service.NutritionService
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.SchemaMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.time.LocalDate

@Controller
class NutritionGraphQLController(
    private val nutritionService: NutritionService,
    private val userService: UserService
) {

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun dailyNutrition(@Argument date: String, @AuthenticationPrincipal jwt: Jwt): DailyNutritionEntity? {
        val user = getUserFromJwt(jwt)
        return nutritionService.getDailyNutrition(user, LocalDate.parse(date))
    }

    @SchemaMapping(typeName = "DailyNutrition", field = "meals")
    fun getMeals(dailyNutrition: DailyNutritionEntity): List<MealEntity> {
        return nutritionService.getMealsForDailyNutrition(dailyNutrition)
    }

    @SchemaMapping(typeName = "Meal", field = "foods")
    fun getFoods(meal: MealEntity): List<MealFoodEntity> {
        return nutritionService.getFoodsForMeal(meal)
    }

    private fun getUserFromJwt(jwt: Jwt): UserEntity {
        val supabaseId = jwt.getClaimAsString("sub")
        val email = jwt.getClaimAsString("email")
        return userService.getOrCreate(supabaseId, email)
    }
}
