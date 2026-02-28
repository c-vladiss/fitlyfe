package com.fitlyfe.fitlyfe_backend.api.nutrition.service

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.MealEntryEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.UserMealTypeEntity
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.DailyNutritionRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealEntryRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.MealRepository
import com.fitlyfe.fitlyfe_backend.api.nutrition.repository.UserMealTypeRepository
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
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
    private val foodEntryRepository: FoodEntryRepository
) {

    // ── Existing queries ────────────────────────────────────────────────

    fun getDailyNutrition(user: UserEntity, date: LocalDate): DailyNutritionEntity? {
        return dailyNutritionRepository.findByUserAndDate(user, date)
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
        val daily = getOrCreateDailyNutrition(user, date)
        val meal = MealEntity(
            dailyNutrition = daily,
            mealType = mealType,
            loggedAt = LocalDateTime.now()
        )
        val saved = mealRepository.save(meal)

        if (isToday(date)) {
            syncMealTypeToTemplate(user, mealType)
        }

        return saved
    }

    @Transactional
    fun renameMealOnDay(user: UserEntity, mealId: UUID, newName: String): MealEntity {
        val meal = verifyMealOwnership(mealId, user)
        val oldName = meal.mealType
        val updated = meal.copy(mealType = newName)
        val saved = mealRepository.save(updated)

        val date = meal.dailyNutrition.date
        if (isToday(date)) {
            // Rename in template if old name exists
            val templateEntry = userMealTypeRepository.findByUserAndName(user, oldName ?: "")
            if (templateEntry != null) {
                userMealTypeRepository.save(templateEntry.copy(name = newName, updatedAt = LocalDateTime.now()))
            }
        }

        return saved
    }

    @Transactional
    fun deleteMealFromDay(user: UserEntity, mealId: UUID) {
        val meal = verifyMealOwnership(mealId, user)
        val daily = meal.dailyNutrition

        mealEntryRepository.deleteByMeal(meal)
        mealRepository.delete(meal)

        recomputeDailyTotals(daily)

        val mealTypeName = meal.mealType
        if (isToday(daily.date) && mealTypeName != null) {
            val templateEntry = userMealTypeRepository.findByUserAndName(user, mealTypeName)
            if (templateEntry != null) {
                userMealTypeRepository.delete(templateEntry)
            }
        }
    }

    // ── Meal Entry CRUD ─────────────────────────────────────────────────

    @Transactional
    fun addMealEntry(
        user: UserEntity,
        date: LocalDate,
        mealType: String,
        foodEntryId: UUID,
        quantityG: Double
    ): MealEntryEntity {
        val foodEntry = foodEntryRepository.findById(foodEntryId)
            .orElseThrow { EntityNotFoundException("Food entry not found: $foodEntryId") }

        val daily = getOrCreateDailyNutrition(user, date)
        val meal = getOrCreateMeal(daily, mealType)

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
        val saved = mealEntryRepository.save(entry)

        recomputeDailyTotals(daily)

        return saved
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

    internal fun getOrCreateDailyNutrition(user: UserEntity, date: LocalDate): DailyNutritionEntity {
        return dailyNutritionRepository.findByUserAndDate(user, date)
            ?: dailyNutritionRepository.save(
                DailyNutritionEntity(user = user, date = date)
            )
    }

    internal fun getOrCreateMeal(dailyNutrition: DailyNutritionEntity, mealType: String): MealEntity {
        return mealRepository.findByDailyNutritionAndMealType(dailyNutrition, mealType)
            ?: mealRepository.save(
                MealEntity(
                    dailyNutrition = dailyNutrition,
                    mealType = mealType,
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

    internal fun isToday(date: LocalDate): Boolean = date == LocalDate.now()

    private fun syncMealTypeToTemplate(user: UserEntity, mealType: String) {
        val existing = userMealTypeRepository.findByUserAndName(user, mealType)
        if (existing == null) {
            val allTypes = userMealTypeRepository.findByUserOrderBySortOrderAsc(user)
            val nextOrder = if (allTypes.isEmpty()) 0 else allTypes.maxOf { it.sortOrder } + 1
            userMealTypeRepository.save(
                UserMealTypeEntity(
                    user = user,
                    name = mealType,
                    sortOrder = nextOrder,
                    isDefault = false
                )
            )
        }
    }

    data class NutritionValues(
        val calories: Int,
        val proteinG: Double,
        val carbsG: Double,
        val fatG: Double
    )
}
