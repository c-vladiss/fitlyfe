package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface MealRepository : JpaRepository<MealEntity, UUID> {
    fun findByDailyNutritionOrderByLoggedAtAsc(dailyNutrition: DailyNutritionEntity): List<MealEntity>
    fun findByDailyNutritionOrderBySortOrderAsc(dailyNutrition: DailyNutritionEntity): List<MealEntity>
    fun findByDailyNutritionAndMealType(dailyNutrition: DailyNutritionEntity, mealType: String): MealEntity?
    fun findByDailyNutrition(dailyNutrition: DailyNutritionEntity): List<MealEntity>
}
