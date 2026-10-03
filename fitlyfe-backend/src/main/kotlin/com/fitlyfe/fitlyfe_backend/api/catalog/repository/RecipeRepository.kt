package com.fitlyfe.fitlyfe_backend.api.catalog.repository

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface RecipeRepository : JpaRepository<RecipeEntity, UUID> {

    fun findByFoodEntry(foodEntry: FoodEntryEntity): RecipeEntity?
}
