package com.fitlyfe.fitlyfe_backend.api.nutrition.service

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealFoodEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.DailyNutritionRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealFoodRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealRepository
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import org.springframework.stereotype.Service
import java.time.LocalDate

@Service
class NutritionService(
    private val dailyNutritionRepository: DailyNutritionRepository,
    private val mealRepository: MealRepository,
    private val mealFoodRepository: MealFoodRepository
) {
    fun getDailyNutrition(user: UserEntity, date: LocalDate): DailyNutritionEntity? {
        return dailyNutritionRepository.findByUserAndDate(user, date)
    }

    fun getMealsForDailyNutrition(dailyNutrition: DailyNutritionEntity): List<MealEntity> {
        return mealRepository.findByDailyNutritionOrderByLoggedAtAsc(dailyNutrition)
    }

    fun getFoodsForMeal(meal: MealEntity): List<MealFoodEntity> {
        return mealFoodRepository.findByMeal(meal)
    }
}
