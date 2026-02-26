package com.fitlyfe.fitlyfe_backend.api.catalog.service

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.Micronutrients
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.RecipeIngredientEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.RecipeIngredientRepository
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.RecipeRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime

@Service
class RecipeNutritionService(
    private val recipeRepository: RecipeRepository,
    private val recipeIngredientRepository: RecipeIngredientRepository,
    private val foodEntryRepository: FoodEntryRepository
) {

    @Transactional(readOnly = true)
    fun findRecipeByFoodEntry(foodEntry: FoodEntryEntity): RecipeEntity? {
        return recipeRepository.findByFoodEntry(foodEntry)
    }

    @Transactional(readOnly = true)
    fun findIngredientsByRecipe(recipe: RecipeEntity): List<RecipeIngredientEntity> {
        return recipeIngredientRepository.findByRecipeOrderByOrderIndexAsc(recipe)
    }

    /**
     * Computes the total nutrition (per 100 g) for a recipe based on its ingredients.
     * Sums each nutrient weighted by ingredient quantity, then normalizes to per-100g.
     * Saves the updated nutrition values to the recipe's food_entry row.
     */
    @Transactional
    fun recomputeNutrition(recipe: RecipeEntity): FoodEntryEntity {
        val ingredients = recipeIngredientRepository.findByRecipeOrderByOrderIndexAsc(recipe)
        val computed = computeNutritionPer100g(ingredients)
        val updated = recipe.foodEntry.copy(
            caloriesPer100g = computed.caloriesPer100g,
            proteinPer100g = computed.proteinPer100g,
            carbsPer100g = computed.carbsPer100g,
            fatPer100g = computed.fatPer100g,
            fiberPer100g = computed.fiberPer100g,
            sugarPer100g = computed.sugarPer100g,
            saturatedFatPer100g = computed.saturatedFatPer100g,
            micronutrients = computed.micronutrients,
            updatedAt = LocalDateTime.now()
        )
        return foodEntryRepository.save(updated)
    }

    private fun computeNutritionPer100g(ingredients: List<RecipeIngredientEntity>): NutritionTotals {
        if (ingredients.isEmpty()) return NutritionTotals()

        val totalWeightG = ingredients.sumOf { it.quantityG }
        if (totalWeightG <= 0) return NutritionTotals()

        var calories = 0.0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber = 0.0
        var sugar = 0.0
        var saturatedFat = 0.0

        // Micronutrient accumulators
        var sodiumMg = 0.0
        var potassiumMg = 0.0
        var calciumMg = 0.0
        var ironMg = 0.0
        var magnesiumMg = 0.0
        var zincMg = 0.0
        var phosphorusMg = 0.0
        var vitaminAMcg = 0.0
        var vitaminCMg = 0.0
        var vitaminDMcg = 0.0
        var vitaminEMg = 0.0
        var vitaminKMcg = 0.0
        var vitaminB6Mg = 0.0
        var vitaminB12Mcg = 0.0
        var folateMcg = 0.0
        var niacinMg = 0.0
        var thiaminMg = 0.0
        var riboflavinMg = 0.0
        var cholesterolMg = 0.0

        for (ingredient in ingredients) {
            val food = ingredient.foodEntry
            val ratio = ingredient.quantityG / 100.0

            calories += (food.caloriesPer100g ?: 0.0) * ratio
            protein += (food.proteinPer100g ?: 0.0) * ratio
            carbs += (food.carbsPer100g ?: 0.0) * ratio
            fat += (food.fatPer100g ?: 0.0) * ratio
            fiber += (food.fiberPer100g ?: 0.0) * ratio
            sugar += (food.sugarPer100g ?: 0.0) * ratio
            saturatedFat += (food.saturatedFatPer100g ?: 0.0) * ratio

            food.micronutrients?.let { m ->
                sodiumMg += (m.sodiumMg ?: 0.0) * ratio
                potassiumMg += (m.potassiumMg ?: 0.0) * ratio
                calciumMg += (m.calciumMg ?: 0.0) * ratio
                ironMg += (m.ironMg ?: 0.0) * ratio
                magnesiumMg += (m.magnesiumMg ?: 0.0) * ratio
                zincMg += (m.zincMg ?: 0.0) * ratio
                phosphorusMg += (m.phosphorusMg ?: 0.0) * ratio
                vitaminAMcg += (m.vitaminAMcg ?: 0.0) * ratio
                vitaminCMg += (m.vitaminCMg ?: 0.0) * ratio
                vitaminDMcg += (m.vitaminDMcg ?: 0.0) * ratio
                vitaminEMg += (m.vitaminEMg ?: 0.0) * ratio
                vitaminKMcg += (m.vitaminKMcg ?: 0.0) * ratio
                vitaminB6Mg += (m.vitaminB6Mg ?: 0.0) * ratio
                vitaminB12Mcg += (m.vitaminB12Mcg ?: 0.0) * ratio
                folateMcg += (m.folateMcg ?: 0.0) * ratio
                niacinMg += (m.niacinMg ?: 0.0) * ratio
                thiaminMg += (m.thiaminMg ?: 0.0) * ratio
                riboflavinMg += (m.riboflavinMg ?: 0.0) * ratio
                cholesterolMg += (m.cholesterolMg ?: 0.0) * ratio
            }
        }

        // Normalize everything to per 100 g
        val factor = 100.0 / totalWeightG

        return NutritionTotals(
            caloriesPer100g = calories * factor,
            proteinPer100g = protein * factor,
            carbsPer100g = carbs * factor,
            fatPer100g = fat * factor,
            fiberPer100g = fiber * factor,
            sugarPer100g = sugar * factor,
            saturatedFatPer100g = saturatedFat * factor,
            micronutrients = Micronutrients(
                sodiumMg = (sodiumMg * factor).takeIf { it > 0 },
                potassiumMg = (potassiumMg * factor).takeIf { it > 0 },
                calciumMg = (calciumMg * factor).takeIf { it > 0 },
                ironMg = (ironMg * factor).takeIf { it > 0 },
                magnesiumMg = (magnesiumMg * factor).takeIf { it > 0 },
                zincMg = (zincMg * factor).takeIf { it > 0 },
                phosphorusMg = (phosphorusMg * factor).takeIf { it > 0 },
                vitaminAMcg = (vitaminAMcg * factor).takeIf { it > 0 },
                vitaminCMg = (vitaminCMg * factor).takeIf { it > 0 },
                vitaminDMcg = (vitaminDMcg * factor).takeIf { it > 0 },
                vitaminEMg = (vitaminEMg * factor).takeIf { it > 0 },
                vitaminKMcg = (vitaminKMcg * factor).takeIf { it > 0 },
                vitaminB6Mg = (vitaminB6Mg * factor).takeIf { it > 0 },
                vitaminB12Mcg = (vitaminB12Mcg * factor).takeIf { it > 0 },
                folateMcg = (folateMcg * factor).takeIf { it > 0 },
                niacinMg = (niacinMg * factor).takeIf { it > 0 },
                thiaminMg = (thiaminMg * factor).takeIf { it > 0 },
                riboflavinMg = (riboflavinMg * factor).takeIf { it > 0 },
                cholesterolMg = (cholesterolMg * factor).takeIf { it > 0 }
            )
        )
    }

    private data class NutritionTotals(
        val caloriesPer100g: Double? = null,
        val proteinPer100g: Double? = null,
        val carbsPer100g: Double? = null,
        val fatPer100g: Double? = null,
        val fiberPer100g: Double? = null,
        val sugarPer100g: Double? = null,
        val saturatedFatPer100g: Double? = null,
        val micronutrients: Micronutrients? = null
    )
}
