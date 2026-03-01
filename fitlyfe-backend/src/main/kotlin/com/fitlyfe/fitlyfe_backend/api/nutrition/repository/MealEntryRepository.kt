package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntryEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface MealEntryRepository : JpaRepository<MealEntryEntity, UUID> {
    fun findByMeal(meal: MealEntity): List<MealEntryEntity>
    fun findByMealIn(meals: List<MealEntity>): List<MealEntryEntity>
    fun deleteByMeal(meal: MealEntity)
}
