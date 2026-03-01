package com.fitlyfe.fitlyfe_backend.api.nutrition.service

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.AddMealEntryResponse
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.DailyGoals
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.DailySummary
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.MealSlot
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.MealSlotEntry
import com.fitlyfe.fitlyfe_backend.api.nutrition.dto.MealSummary
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntryEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.UserMealTypeEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.DailyNutritionRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealEntryRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.UserMealTypeRepository
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserGoalsEntity
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import jakarta.persistence.EntityNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

@Service
class NutritionService(
    private val dailyNutritionRepository: DailyNutritionRepository,
    private val mealRepository: MealRepository,
    private val mealEntryRepository: MealEntryRepository,
    private val userMealTypeRepository: UserMealTypeRepository,
    private val foodEntryRepository: FoodEntryRepository,
    private val userService: UserService
) {

    // ── Existing queries ────────────────────────────────────────────────

    /**
     * Get daily nutrition for a date, initializing from default template if pristine.
     * This ensures every queried day has actual MealEntity records.
     */
    @Transactional
    fun getDailyNutrition(user: UserEntity, date: LocalDate): DailyNutritionEntity {
        val existing = dailyNutritionRepository.findByUserAndDate(user, date)
        if (existing != null) {
            return existing
        }

        // Initialize new day with default template
        return initializeDayFromTemplate(user, date)
    }

    /**
     * Initialize a new day by creating DailyNutritionEntity and MealEntity records
     * for each meal type in the user's default template.
     */
    private fun initializeDayFromTemplate(user: UserEntity, date: LocalDate): DailyNutritionEntity {
        val daily = dailyNutritionRepository.save(
            DailyNutritionEntity(user = user, date = date)
        )

        // Create MealEntity for each default meal type
        val mealTypes = getOrInitMealTypes(user)
        mealTypes.forEach { mealType ->
            mealRepository.save(
                MealEntity(
                    dailyNutrition = daily,
                    mealType = mealType.name,
                    sortOrder = mealType.sortOrder,
                    loggedAt = LocalDateTime.now()
                )
            )
        }

        return daily
    }

    fun getMealsForDailyNutrition(dailyNutrition: DailyNutritionEntity): List<MealEntity> {
        return mealRepository.findByDailyNutritionOrderByLoggedAtAsc(dailyNutrition)
    }

    fun getEntriesForMeal(meal: MealEntity): List<MealEntryEntity> {
        return mealEntryRepository.findByMeal(meal)
    }

    // ── Meal Type Template ──────────────────────────────────────────────

    private val defaultMealTypes = listOf(
        "Breakfast" to 0,
        "Lunch" to 1,
        "Dinner" to 2
    )

    fun getOrInitMealTypes(user: UserEntity): List<UserMealTypeEntity> {
        val existing = userMealTypeRepository.findByUserOrderBySortOrderAsc(user)
        if (existing.isNotEmpty()) return existing

        val defaults = defaultMealTypes.map { (name, order) ->
            UserMealTypeEntity(
                user = user,
                name = name,
                sortOrder = order,
                isDefault = true
            )
        }
        return userMealTypeRepository.saveAll(defaults)
    }

    @Transactional
    fun createUserMealTypes(user: UserEntity, types: List<Pair<String, Int>>): List<UserMealTypeEntity> {
        userMealTypeRepository.deleteAllByUser(user)
        val entities = types.map { (name, sortOrder) ->
            UserMealTypeEntity(
                user = user,
                name = name,
                sortOrder = sortOrder,
                isDefault = false
            )
        }
        return userMealTypeRepository.saveAll(entities)
    }

    fun addUserMealType(user: UserEntity, name: String, sortOrder: Int): UserMealTypeEntity {
        val entity = UserMealTypeEntity(
            user = user,
            name = name,
            sortOrder = sortOrder,
            isDefault = false
        )
        return userMealTypeRepository.save(entity)
    }

    fun updateUserMealType(user: UserEntity, id: UUID, name: String?, sortOrder: Int?): UserMealTypeEntity {
        val existing = userMealTypeRepository.findById(id)
            .orElseThrow { EntityNotFoundException("Meal type not found: $id") }
        if (existing.user.id != user.id) {
            throw IllegalArgumentException("Meal type does not belong to user")
        }
        val updated = existing.copy(
            name = name ?: existing.name,
            sortOrder = sortOrder ?: existing.sortOrder,
            updatedAt = LocalDateTime.now()
        )
        return userMealTypeRepository.save(updated)
    }

    fun deleteUserMealType(user: UserEntity, id: UUID) {
        val existing = userMealTypeRepository.findById(id)
            .orElseThrow { EntityNotFoundException("Meal type not found: $id") }
        if (existing.user.id != user.id) {
            throw IllegalArgumentException("Meal type does not belong to user")
        }
        userMealTypeRepository.delete(existing)
    }

    // ── Per-Day Meal Management ─────────────────────────────────────────

    @Transactional
    fun addMealToDay(user: UserEntity, date: LocalDate, mealType: String): MealEntity {
        // getDailyNutrition initializes day from template if pristine
        val daily = getDailyNutrition(user, date)

        // Calculate next sortOrder
        val existingMeals = mealRepository.findByDailyNutritionOrderBySortOrderAsc(daily)
        val nextSortOrder = if (existingMeals.isEmpty()) 0 else existingMeals.maxOf { it.sortOrder } + 1

        val meal = MealEntity(
            dailyNutrition = daily,
            mealType = mealType,
            sortOrder = nextSortOrder,
            loggedAt = LocalDateTime.now()
        )
        return mealRepository.save(meal)
    }

    @Transactional
    fun renameMealOnDay(user: UserEntity, mealId: UUID, newName: String): MealEntity {
        val meal = verifyMealOwnership(mealId, user)
        val updated = meal.copy(mealType = newName)
        return mealRepository.save(updated)
    }

    @Transactional
    fun deleteMealFromDay(user: UserEntity, mealId: UUID) {
        val meal = verifyMealOwnership(mealId, user)
        val daily = meal.dailyNutrition

        mealEntryRepository.deleteByMeal(meal)
        mealRepository.delete(meal)

        recomputeDailyTotals(daily)
    }

    // ── Meal Entry CRUD ─────────────────────────────────────────────────

    @Transactional
    fun addMealEntry(
        user: UserEntity,
        date: LocalDate,
        mealType: String,
        foodEntryId: UUID,
        quantityG: Double
    ): AddMealEntryResponse {
        val foodEntry = foodEntryRepository.findById(foodEntryId)
            .orElseThrow { EntityNotFoundException("Food entry not found: $foodEntryId") }

        // getDailyNutrition initializes day from template if pristine
        val daily = getDailyNutrition(user, date)

        // Find existing meal or create if it was deleted and user wants to add to it
        val meal = getOrCreateMealForDay(daily, mealType)

        val (calories, protein, carbs, fat) = computeEntryNutrition(foodEntry, quantityG)

        val entry = MealEntryEntity(
            meal = meal,
            foodEntry = foodEntry,
            quantityG = quantityG,
            calories = calories,
            proteinG = protein,
            carbsG = carbs,
            fatG = fat
        )
        val savedEntry = mealEntryRepository.save(entry)

        recomputeDailyTotals(daily)

        // Build meal summary (all entries in this meal)
        val mealSummary = computeMealSummary(meal)

        // Get updated daily summary
        val updatedDaily = dailyNutritionRepository.findByUserAndDate(user, date)!!
        val dailySummary = DailySummary(
            totalCaloriesConsumed = updatedDaily.totalCalories ?: 0,
            proteinGConsumed = updatedDaily.proteinG ?: 0.0,
            carbsGConsumed = updatedDaily.carbsG ?: 0.0,
            fatGConsumed = updatedDaily.fatG ?: 0.0
        )

        return AddMealEntryResponse(
            entry = savedEntry,
            mealSummary = mealSummary,
            dailySummary = dailySummary
        )
    }

    @Transactional
    fun updateMealEntry(
        user: UserEntity,
        entryId: UUID,
        quantityG: Double?,
        foodEntryId: UUID?
    ): MealEntryEntity {
        val existing = verifyEntryOwnership(entryId, user)

        val foodEntry = if (foodEntryId != null) {
            foodEntryRepository.findById(foodEntryId)
                .orElseThrow { EntityNotFoundException("Food entry not found: $foodEntryId") }
        } else {
            existing.foodEntry
        }

        val newQuantity = quantityG ?: existing.quantityG ?: 0.0
        val (calories, protein, carbs, fat) = computeEntryNutrition(foodEntry, newQuantity)

        val updated = existing.copy(
            foodEntry = foodEntry,
            quantityG = newQuantity,
            calories = calories,
            proteinG = protein,
            carbsG = carbs,
            fatG = fat
        )
        val saved = mealEntryRepository.save(updated)

        recomputeDailyTotals(existing.meal.dailyNutrition)

        return saved
    }

    @Transactional
    fun deleteMealEntry(user: UserEntity, entryId: UUID) {
        val existing = verifyEntryOwnership(entryId, user)
        val daily = existing.meal.dailyNutrition

        mealEntryRepository.delete(existing)

        recomputeDailyTotals(daily)
    }

    // ── Queries ─────────────────────────────────────────────────────────

    fun getWeeklyNutrition(
        user: UserEntity,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<DailyNutritionEntity> {
        return dailyNutritionRepository.findByUserAndDateBetween(user, startDate, endDate)
    }

    // ── Internal Helpers ────────────────────────────────────────────────

    /**
     * Get or create a meal for a specific day.
     * If the meal was previously deleted and user adds food to it, re-create with next sortOrder.
     */
    internal fun getOrCreateMealForDay(dailyNutrition: DailyNutritionEntity, mealType: String): MealEntity {
        val existing = mealRepository.findByDailyNutritionAndMealType(dailyNutrition, mealType)
        if (existing != null) return existing

        // Meal doesn't exist (was deleted), create it with next sortOrder
        val meals = mealRepository.findByDailyNutritionOrderBySortOrderAsc(dailyNutrition)
        val nextSortOrder = if (meals.isEmpty()) 0 else meals.maxOf { it.sortOrder } + 1

        return mealRepository.save(
            MealEntity(
                dailyNutrition = dailyNutrition,
                mealType = mealType,
                sortOrder = nextSortOrder,
                loggedAt = LocalDateTime.now()
            )
        )
    }

    internal fun recomputeDailyTotals(dailyNutrition: DailyNutritionEntity) {
        val meals = mealRepository.findByDailyNutrition(dailyNutrition)
        val entries = if (meals.isNotEmpty()) mealEntryRepository.findByMealIn(meals) else emptyList()

        val totalCalories = entries.sumOf { it.calories ?: 0 }
        val totalProtein = entries.sumOf { it.proteinG ?: 0.0 }
        val totalCarbs = entries.sumOf { it.carbsG ?: 0.0 }
        val totalFat = entries.sumOf { it.fatG ?: 0.0 }

        val updated = dailyNutrition.copy(
            totalCalories = totalCalories,
            proteinG = totalProtein,
            carbsG = totalCarbs,
            fatG = totalFat,
            updatedAt = LocalDateTime.now()
        )
        dailyNutritionRepository.save(updated)
    }

    internal fun computeEntryNutrition(foodEntry: FoodEntryEntity, quantityG: Double): NutritionValues {
        val factor = quantityG / 100.0
        return NutritionValues(
            calories = ((foodEntry.caloriesPer100g ?: 0.0) * factor).toInt(),
            proteinG = (foodEntry.proteinPer100g ?: 0.0) * factor,
            carbsG = (foodEntry.carbsPer100g ?: 0.0) * factor,
            fatG = (foodEntry.fatPer100g ?: 0.0) * factor
        )
    }

    internal fun verifyEntryOwnership(entryId: UUID, user: UserEntity): MealEntryEntity {
        val entry = mealEntryRepository.findById(entryId)
            .orElseThrow { EntityNotFoundException("Meal entry not found: $entryId") }
        val owner = entry.meal.dailyNutrition.user
        if (owner.id != user.id) {
            throw IllegalArgumentException("Meal entry does not belong to user")
        }
        return entry
    }

    internal fun verifyMealOwnership(mealId: UUID, user: UserEntity): MealEntity {
        val meal = mealRepository.findById(mealId)
            .orElseThrow { EntityNotFoundException("Meal not found: $mealId") }
        val owner = meal.dailyNutrition.user
        if (owner.id != user.id) {
            throw IllegalArgumentException("Meal does not belong to user")
        }
        return meal
    }

    data class NutritionValues(
        val calories: Int,
        val proteinG: Double,
        val carbsG: Double,
        val fatG: Double
    )

    // ── Goals & Meal Template ───────────────────────────────────────────

    /**
     * Get daily goals for a user
     */
    fun getDailyGoals(user: UserEntity): DailyGoals {
        val goals = userService.getOrCreateGoals(user)
        return DailyGoals(
            totalCalories = goals.dailyCalories,
            totalProteinG = goals.dailyProteinG,
            totalCarbsG = goals.dailyCarbsG,
            totalFatG = goals.dailyFatG
        )
    }

    /**
     * Build meal template for a specific day with per-meal goal distribution.
     *
     * Logic:
     * - Uses ACTUAL MealEntity records for this day (day is initialized on first query)
     * - Goals are distributed equally across all meals in the day's template
     * - Includes simplified entry info for each slot
     *
     * Note: getDailyNutrition() must be called first to ensure day is initialized.
     */
    fun getMealTemplate(user: UserEntity, daily: DailyNutritionEntity): List<MealSlot> {
        val goals = userService.getOrCreateGoals(user)

        // Get actual meals for this day (ordered by sortOrder)
        val meals = mealRepository.findByDailyNutritionOrderBySortOrderAsc(daily)
        val numberOfMeals = meals.size.coerceAtLeast(1)

        // Calculate per-meal targets (equal distribution across day's meals)
        val targetCaloriesPerMeal = goals.dailyCalories / numberOfMeals
        val targetProteinPerMeal = goals.dailyProteinG / numberOfMeals
        val targetCarbsPerMeal = goals.dailyCarbsG / numberOfMeals
        val targetFatPerMeal = goals.dailyFatG / numberOfMeals

        // Build meal slots from actual meals
        return meals.map { meal ->
            val entries = mealEntryRepository.findByMeal(meal)

            // Calculate consumed totals
            val consumedCalories = if (entries.isNotEmpty()) entries.sumOf { it.calories ?: 0 } else null
            val consumedProteinG = if (entries.isNotEmpty()) entries.sumOf { it.proteinG ?: 0.0 } else null
            val consumedCarbsG = if (entries.isNotEmpty()) entries.sumOf { it.carbsG ?: 0.0 } else null
            val consumedFatG = if (entries.isNotEmpty()) entries.sumOf { it.fatG ?: 0.0 } else null

            // Build simplified entry list (name + macros only)
            val slotEntries = entries.map { entry ->
                MealSlotEntry(
                    id = entry.id,
                    name = entry.foodEntry.name,
                    quantityG = entry.quantityG,
                    calories = entry.calories,
                    proteinG = entry.proteinG,
                    carbsG = entry.carbsG,
                    fatG = entry.fatG
                )
            }

            MealSlot(
                name = meal.mealType ?: "Meal",
                sortOrder = meal.sortOrder,
                targetCalories = targetCaloriesPerMeal,
                targetProteinG = targetProteinPerMeal,
                targetCarbsG = targetCarbsPerMeal,
                targetFatG = targetFatPerMeal,
                consumedCalories = consumedCalories,
                consumedProteinG = consumedProteinG,
                consumedCarbsG = consumedCarbsG,
                consumedFatG = consumedFatG,
                entries = slotEntries
            )
        }
    }

    /**
     * Compute summary for a single meal (sum of all entries)
     */
    internal fun computeMealSummary(meal: MealEntity): MealSummary {
        val entries = mealEntryRepository.findByMeal(meal)
        return MealSummary(
            mealId = meal.id,
            mealType = meal.mealType ?: "Unknown",
            totalCalories = entries.sumOf { it.calories ?: 0 },
            proteinG = entries.sumOf { it.proteinG ?: 0.0 },
            carbsG = entries.sumOf { it.carbsG ?: 0.0 },
            fatG = entries.sumOf { it.fatG ?: 0.0 }
        )
    }
}
