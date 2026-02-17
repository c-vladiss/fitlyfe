package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealFoodEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface MealFoodRepository : JpaRepository<MealFoodEntity, UUID> {
    fun findByMeal(meal: MealEntity): List<MealFoodEntity>
}
