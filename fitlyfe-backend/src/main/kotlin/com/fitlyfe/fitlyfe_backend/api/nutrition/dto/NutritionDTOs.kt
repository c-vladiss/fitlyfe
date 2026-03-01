package com.fitlyfe.fitlyfe_backend.api.nutrition.dto

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntryEntity
import java.util.UUID

/**
 * Daily nutrition goals from user_goals table
 */
data class DailyGoals(
    val totalCalories: Int,
    val totalProteinG: Double,
    val totalCarbsG: Double,
    val totalFatG: Double
)

/**
 * A meal slot in the day's template with per-meal targets and consumed values
 */
data class MealSlot(
    val name: String,
    val sortOrder: Int,
    // Per-meal targets (total goals / number of meals)
    val targetCalories: Int,
    val targetProteinG: Double,
    val targetCarbsG: Double,
    val targetFatG: Double,
    // Consumed totals for this slot (sum of entries)
    val consumedCalories: Int?,
    val consumedProteinG: Double?,
    val consumedCarbsG: Double?,
    val consumedFatG: Double?,
    // Logged food entries (simplified for daily view)
    val entries: List<MealSlotEntry>
)

/**
 * Simplified entry for daily view (name + macros only)
 */
data class MealSlotEntry(
    val id: UUID,
    val name: String,
    val quantityG: Double?,
    val calories: Int?,
    val proteinG: Double?,
    val carbsG: Double?,
    val fatG: Double?
)

/**
 * Response for addMealEntry mutation
 */
data class AddMealEntryResponse(
    val entry: MealEntryEntity,
    val mealSummary: MealSummary,
    val dailySummary: DailySummary
)

/**
 * Summary of a meal's nutritional totals
 */
data class MealSummary(
    val mealId: UUID,
    val mealType: String,
    val totalCalories: Int,
    val proteinG: Double,
    val carbsG: Double,
    val fatG: Double
)

/**
 * Summary of daily nutritional totals
 */
data class DailySummary(
    val totalCaloriesConsumed: Int,
    val proteinGConsumed: Double,
    val carbsGConsumed: Double,
    val fatGConsumed: Double
)
