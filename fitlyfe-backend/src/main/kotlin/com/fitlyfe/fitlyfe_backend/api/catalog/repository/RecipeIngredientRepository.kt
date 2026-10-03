package com.fitlyfe.fitlyfe_backend.api.catalog.repository

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeIngredientEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface RecipeIngredientRepository : JpaRepository<RecipeIngredientEntity, UUID> {

    fun findByRecipeOrderByOrderIndexAsc(recipe: RecipeEntity): List<RecipeIngredientEntity>
}
