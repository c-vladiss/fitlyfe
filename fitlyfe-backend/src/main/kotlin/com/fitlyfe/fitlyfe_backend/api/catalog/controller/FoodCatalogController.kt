package com.fitlyfe.fitlyfe_backend.api.catalog.controller

import com.fitlyfe.fitlyfe_backend.api.catalog.dto.FoodSearchResult
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeIngredientEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.service.FoodCatalogService
import com.fitlyfe.fitlyfe_backend.api.catalog.service.RecipeNutritionService
import org.springframework.graphql.data.method.annotation.Argument
import org.springframework.graphql.data.method.annotation.QueryMapping
import org.springframework.graphql.data.method.annotation.SchemaMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.stereotype.Controller
import java.util.UUID

@Controller
class FoodCatalogController(
    private val foodCatalogService: FoodCatalogService,
    private val recipeNutritionService: RecipeNutritionService
) {

    // ------------------------------------------------------------------
    // Queries
    // ------------------------------------------------------------------

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun searchFoodCatalog(
        @Argument query: String,
        @Argument types: List<FoodEntryType>?,
        @Argument limit: Int?,
        @Argument offset: Int?
    ): FoodSearchResult {
        return foodCatalogService.search(
            query = query.trim(),
            types = types,
            limit = (limit ?: 20).coerceIn(1, 100),
            offset = (offset ?: 0).coerceAtLeast(0)
        )
    }

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun foodEntryById(@Argument id: String): FoodEntryEntity? {
        return foodCatalogService.findById(UUID.fromString(id))
    }

    @QueryMapping
    @PreAuthorize("isAuthenticated()")
    fun foodEntryByBarcode(@Argument barcode: String): FoodEntryEntity? {
        val sanitized = barcode.trim()
        if (sanitized.isBlank()) return null
        return foodCatalogService.findByBarcode(sanitized)
    }

    // ------------------------------------------------------------------
    // Schema mappings (nested type resolution)
    // ------------------------------------------------------------------

    @SchemaMapping(typeName = "FoodEntry", field = "recipe")
    fun recipe(foodEntry: FoodEntryEntity): RecipeEntity? {
        if (foodEntry.entryType != FoodEntryType.RECIPE) return null
        return recipeNutritionService.findRecipeByFoodEntry(foodEntry)
    }

    @SchemaMapping(typeName = "Recipe", field = "ingredients")
    fun ingredients(recipe: RecipeEntity): List<RecipeIngredientEntity> {
        return recipeNutritionService.findIngredientsByRecipe(recipe)
    }

    @SchemaMapping(typeName = "RecipeIngredient", field = "food")
    fun ingredientFood(ingredient: RecipeIngredientEntity): FoodEntryEntity {
        return ingredient.foodEntry
    }
}
