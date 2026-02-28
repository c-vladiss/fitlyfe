package com.fitlyfe.fitlyfe_backend.api.nutrition.service

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
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
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.api.Assertions.assertThatThrownBy
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

@ExtendWith(MockitoExtension::class)
class NutritionServiceTest {

    @Mock private lateinit var dailyNutritionRepository: DailyNutritionRepository
    @Mock private lateinit var mealRepository: MealRepository
    @Mock private lateinit var mealEntryRepository: MealEntryRepository
    @Mock private lateinit var userMealTypeRepository: UserMealTypeRepository
    @Mock private lateinit var foodEntryRepository: FoodEntryRepository

    private lateinit var service: NutritionService

    private val user = UserEntity(
        supabaseId = UUID.randomUUID(),
        email = "test@example.com"
    )

    @BeforeEach
    fun setUp() {
        service = NutritionService(
            dailyNutritionRepository,
            mealRepository,
            mealEntryRepository,
            userMealTypeRepository,
            foodEntryRepository
        )
    }

    private fun foodEntry(
        name: String = "Chicken Breast",
        caloriesPer100g: Double = 165.0,
        proteinPer100g: Double = 31.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 3.6
    ) = FoodEntryEntity(
        name = name,
        entryType = FoodEntryType.FOOD,
        entrySource = FoodEntrySource.USDA,
        caloriesPer100g = caloriesPer100g,
        proteinPer100g = proteinPer100g,
        carbsPer100g = carbsPer100g,
        fatPer100g = fatPer100g
    )

    private fun dailyNutrition(date: LocalDate = LocalDate.now()) = DailyNutritionEntity(
        user = user,
        date = date
    )

    private fun meal(daily: DailyNutritionEntity, mealType: String = "Lunch") = MealEntity(
        dailyNutrition = daily,
        mealType = mealType,
        loggedAt = LocalDateTime.now()
    )

    private fun mealEntry(meal: MealEntity, food: FoodEntryEntity, quantityG: Double = 100.0) = MealEntryEntity(
        meal = meal,
        foodEntry = food,
        quantityG = quantityG,
        calories = ((food.caloriesPer100g ?: 0.0) * quantityG / 100.0).toInt(),
        proteinG = (food.proteinPer100g ?: 0.0) * quantityG / 100.0,
        carbsG = (food.carbsPer100g ?: 0.0) * quantityG / 100.0,
        fatG = (food.fatPer100g ?: 0.0) * quantityG / 100.0
    )

    // ── User Meal Types ─────────────────────────────────────────────────

    @Nested
    inner class UserMealTypes {

        @Test
        fun `getOrInitMealTypes returns existing types`() {
            val types = listOf(
                UserMealTypeEntity(user = user, name = "Breakfast", sortOrder = 0),
                UserMealTypeEntity(user = user, name = "Lunch", sortOrder = 1)
            )
            whenever(userMealTypeRepository.findByUserOrderBySortOrderAsc(user)).thenReturn(types)

            val result = service.getOrInitMealTypes(user)

            assertThat(result).isEqualTo(types)
            verify(userMealTypeRepository, never()).saveAll(any<List<UserMealTypeEntity>>())
        }

        @Test
        fun `getOrInitMealTypes creates defaults when none exist`() {
            whenever(userMealTypeRepository.findByUserOrderBySortOrderAsc(user)).thenReturn(emptyList())
            whenever(userMealTypeRepository.saveAll(any<List<UserMealTypeEntity>>())).thenAnswer { it.arguments[0] }

            val result = service.getOrInitMealTypes(user)

            assertThat(result).hasSize(3)
            verify(userMealTypeRepository).saveAll(argThat<List<UserMealTypeEntity>> {
                this.size == 3 &&
                    this[0].name == "Breakfast" &&
                    this[1].name == "Lunch" &&
                    this[2].name == "Dinner"
            })
        }

        @Test
        fun `createUserMealTypes replaces all existing types`() {
            whenever(userMealTypeRepository.saveAll(any<List<UserMealTypeEntity>>())).thenAnswer { it.arguments[0] }

            val types = listOf("Morning" to 0, "Evening" to 1)
            service.createUserMealTypes(user, types)

            verify(userMealTypeRepository).deleteAllByUser(user)
            verify(userMealTypeRepository).saveAll(argThat<List<UserMealTypeEntity>> {
                this.size == 2 && this[0].name == "Morning" && this[1].name == "Evening"
            })
        }

        @Test
        fun `addUserMealType saves new type`() {
            val expected = UserMealTypeEntity(user = user, name = "Snack", sortOrder = 3)
            doReturn(expected).whenever(userMealTypeRepository).save(any<UserMealTypeEntity>())

            val result = service.addUserMealType(user, "Snack", 3)

            assertThat(result.name).isEqualTo("Snack")
            assertThat(result.sortOrder).isEqualTo(3)
        }

        @Test
        fun `updateUserMealType updates name and sortOrder`() {
            val existing = UserMealTypeEntity(user = user, name = "Lunch", sortOrder = 1)
            whenever(userMealTypeRepository.findById(existing.id)).thenReturn(Optional.of(existing))
            doAnswer { it.arguments[0] }.whenever(userMealTypeRepository).save(any<UserMealTypeEntity>())

            val result = service.updateUserMealType(user, existing.id, "Brunch", 0)

            assertThat(result.name).isEqualTo("Brunch")
            assertThat(result.sortOrder).isEqualTo(0)
        }

        @Test
        fun `updateUserMealType throws when not found`() {
            val id = UUID.randomUUID()
            whenever(userMealTypeRepository.findById(id)).thenReturn(Optional.empty())

            assertThatThrownBy { service.updateUserMealType(user, id, "X", null) }
                .isInstanceOf(EntityNotFoundException::class.java)
        }

        @Test
        fun `updateUserMealType throws when different user`() {
            val otherUser = UserEntity(supabaseId = UUID.randomUUID(), email = "other@test.com")
            val existing = UserMealTypeEntity(user = otherUser, name = "Lunch", sortOrder = 1)
            whenever(userMealTypeRepository.findById(existing.id)).thenReturn(Optional.of(existing))

            assertThatThrownBy { service.updateUserMealType(user, existing.id, "X", null) }
                .isInstanceOf(IllegalArgumentException::class.java)
        }

        @Test
        fun `deleteUserMealType removes type`() {
            val existing = UserMealTypeEntity(user = user, name = "Snack", sortOrder = 3)
            whenever(userMealTypeRepository.findById(existing.id)).thenReturn(Optional.of(existing))

            service.deleteUserMealType(user, existing.id)

            verify(userMealTypeRepository).delete(existing)
        }
    }

    // ── Add Meal Entry ──────────────────────────────────────────────────

    @Nested
    inner class AddMealEntry {

        @Test
        fun `creates daily nutrition and meal if not exist then adds entry`() {
            val date = LocalDate.of(2026, 1, 15)
            val food = foodEntry()
            val daily = dailyNutrition(date)
            val mealObj = meal(daily, "Lunch")

            whenever(foodEntryRepository.findById(food.id)).thenReturn(Optional.of(food))
            whenever(dailyNutritionRepository.findByUserAndDate(user, date)).thenReturn(null)
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())
            whenever(mealRepository.findByDailyNutritionAndMealType(daily, "Lunch")).thenReturn(null)
            doReturn(mealObj).whenever(mealRepository).save(any<MealEntity>())
            doAnswer { it.arguments[0] }.whenever(mealEntryRepository).save(any<MealEntryEntity>())
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(listOf(mealObj))
            whenever(mealEntryRepository.findByMealIn(listOf(mealObj))).thenReturn(emptyList())

            val result = service.addMealEntry(user, date, "Lunch", food.id, 200.0)

            assertThat(result.quantityG).isEqualTo(200.0)
            assertThat(result.calories).isEqualTo(330) // 165 * 2
            assertThat(result.proteinG).isEqualTo(62.0) // 31 * 2
            verify(dailyNutritionRepository, times(2)).save(any<DailyNutritionEntity>()) // create + recompute
        }

        @Test
        fun `reuses existing daily nutrition and meal`() {
            val date = LocalDate.of(2026, 1, 15)
            val food = foodEntry()
            val daily = dailyNutrition(date)
            val mealObj = meal(daily, "Lunch")

            whenever(foodEntryRepository.findById(food.id)).thenReturn(Optional.of(food))
            whenever(dailyNutritionRepository.findByUserAndDate(user, date)).thenReturn(daily)
            whenever(mealRepository.findByDailyNutritionAndMealType(daily, "Lunch")).thenReturn(mealObj)
            doAnswer { it.arguments[0] }.whenever(mealEntryRepository).save(any<MealEntryEntity>())
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(listOf(mealObj))
            whenever(mealEntryRepository.findByMealIn(listOf(mealObj))).thenReturn(emptyList())
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())

            service.addMealEntry(user, date, "Lunch", food.id, 100.0)

            // dailyNutritionRepository.save called once (recompute only)
            verify(dailyNutritionRepository, times(1)).save(any<DailyNutritionEntity>())
        }

        @Test
        fun `throws when food entry not found`() {
            val id = UUID.randomUUID()
            whenever(foodEntryRepository.findById(id)).thenReturn(Optional.empty())

            assertThatThrownBy { service.addMealEntry(user, LocalDate.now(), "Lunch", id, 100.0) }
                .isInstanceOf(EntityNotFoundException::class.java)
        }
    }

    // ── Update Meal Entry ───────────────────────────────────────────────

    @Nested
    inner class UpdateMealEntry {

        @Test
        fun `updates quantity and recomputes nutrition`() {
            val food = foodEntry()
            val daily = dailyNutrition()
            val mealObj = meal(daily)
            val entry = mealEntry(mealObj, food, 100.0)

            whenever(mealEntryRepository.findById(entry.id)).thenReturn(Optional.of(entry))
            doAnswer { it.arguments[0] }.whenever(mealEntryRepository).save(any<MealEntryEntity>())
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(listOf(mealObj))
            whenever(mealEntryRepository.findByMealIn(listOf(mealObj))).thenReturn(emptyList())
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())

            val result = service.updateMealEntry(user, entry.id, 200.0, null)

            assertThat(result.quantityG).isEqualTo(200.0)
            assertThat(result.calories).isEqualTo(330)
        }

        @Test
        fun `updates food entry and recomputes`() {
            val food1 = foodEntry("Chicken", caloriesPer100g = 165.0)
            val food2 = foodEntry("Rice", caloriesPer100g = 130.0, proteinPer100g = 2.7, carbsPer100g = 28.0, fatPer100g = 0.3)
            val daily = dailyNutrition()
            val mealObj = meal(daily)
            val entry = mealEntry(mealObj, food1, 100.0)

            whenever(mealEntryRepository.findById(entry.id)).thenReturn(Optional.of(entry))
            whenever(foodEntryRepository.findById(food2.id)).thenReturn(Optional.of(food2))
            doAnswer { it.arguments[0] }.whenever(mealEntryRepository).save(any<MealEntryEntity>())
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(listOf(mealObj))
            whenever(mealEntryRepository.findByMealIn(listOf(mealObj))).thenReturn(emptyList())
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())

            val result = service.updateMealEntry(user, entry.id, null, food2.id)

            assertThat(result.foodEntry).isEqualTo(food2)
            assertThat(result.calories).isEqualTo(130)
        }

        @Test
        fun `throws when entry belongs to different user`() {
            val otherUser = UserEntity(supabaseId = UUID.randomUUID(), email = "other@test.com")
            val daily = DailyNutritionEntity(user = otherUser, date = LocalDate.now())
            val mealObj = meal(daily)
            val food = foodEntry()
            val entry = mealEntry(mealObj, food)

            whenever(mealEntryRepository.findById(entry.id)).thenReturn(Optional.of(entry))

            assertThatThrownBy { service.updateMealEntry(user, entry.id, 200.0, null) }
                .isInstanceOf(IllegalArgumentException::class.java)
        }
    }

    // ── Delete Meal Entry ───────────────────────────────────────────────

    @Nested
    inner class DeleteMealEntry {

        @Test
        fun `deletes entry and recomputes daily totals`() {
            val food = foodEntry()
            val daily = dailyNutrition()
            val mealObj = meal(daily)
            val entry = mealEntry(mealObj, food)

            whenever(mealEntryRepository.findById(entry.id)).thenReturn(Optional.of(entry))
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(listOf(mealObj))
            whenever(mealEntryRepository.findByMealIn(listOf(mealObj))).thenReturn(emptyList())
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())

            service.deleteMealEntry(user, entry.id)

            verify(mealEntryRepository).delete(entry)
            verify(dailyNutritionRepository).save(any<DailyNutritionEntity>())
        }
    }

    // ── Delete Meal ─────────────────────────────────────────────────────

    @Nested
    inner class DeleteMeal {

        @Test
        fun `deletes meal entries and meal, recomputes totals`() {
            val daily = dailyNutrition(LocalDate.of(2026, 1, 15)) // not today
            val mealObj = meal(daily, "Lunch")

            whenever(mealRepository.findById(mealObj.id)).thenReturn(Optional.of(mealObj))
            whenever(mealRepository.findByDailyNutrition(daily)).thenReturn(emptyList())
            doReturn(daily).whenever(dailyNutritionRepository).save(any<DailyNutritionEntity>())

            service.deleteMealFromDay(user, mealObj.id)

            verify(mealEntryRepository).deleteByMeal(mealObj)
            verify(mealRepository).delete(mealObj)
            verify(dailyNutritionRepository).save(any<DailyNutritionEntity>())
        }
    }

    // ── Daily Meal Management ───────────────────────────────────────────

    @Nested
    inner class DailyMealManagement {

        @Test
        fun `addMealToDay creates meal for given date`() {
            val date = LocalDate.of(2026, 1, 15) // not today
            val daily = dailyNutrition(date)

            whenever(dailyNutritionRepository.findByUserAndDate(user, date)).thenReturn(daily)
            doAnswer { it.arguments[0] }.whenever(mealRepository).save(any<MealEntity>())

            val result = service.addMealToDay(user, date, "Snack")

            assertThat(result.mealType).isEqualTo("Snack")
            // Not today, so template should NOT be updated
            verifyNoInteractions(userMealTypeRepository)
        }

        @Test
        fun `renameMealOnDay renames meal on past day without template change`() {
            val date = LocalDate.of(2026, 1, 15)
            val daily = dailyNutrition(date)
            val mealObj = meal(daily, "Lunch")

            whenever(mealRepository.findById(mealObj.id)).thenReturn(Optional.of(mealObj))
            doAnswer { it.arguments[0] }.whenever(mealRepository).save(any<MealEntity>())

            val result = service.renameMealOnDay(user, mealObj.id, "Brunch")

            assertThat(result.mealType).isEqualTo("Brunch")
            verifyNoInteractions(userMealTypeRepository)
        }
    }

    // ── Weekly Nutrition ────────────────────────────────────────────────

    @Nested
    inner class WeeklyNutrition {

        @Test
        fun `returns daily nutrition entries for date range`() {
            val start = LocalDate.of(2026, 1, 13)
            val end = LocalDate.of(2026, 1, 19)
            val days = listOf(dailyNutrition(start), dailyNutrition(end))

            whenever(dailyNutritionRepository.findByUserAndDateBetween(user, start, end)).thenReturn(days)

            val result = service.getWeeklyNutrition(user, start, end)

            assertThat(result).hasSize(2)
        }
    }

    // ── Compute Nutrition ───────────────────────────────────────────────

    @Nested
    inner class ComputeNutrition {

        @Test
        fun `computes per-100g values scaled to quantity`() {
            val food = foodEntry(
                caloriesPer100g = 200.0,
                proteinPer100g = 20.0,
                carbsPer100g = 30.0,
                fatPer100g = 10.0
            )

            val result = service.computeEntryNutrition(food, 250.0)

            assertThat(result.calories).isEqualTo(500)
            assertThat(result.proteinG).isEqualTo(50.0)
            assertThat(result.carbsG).isEqualTo(75.0)
            assertThat(result.fatG).isEqualTo(25.0)
        }

        @Test
        fun `handles null per-100g values as zero`() {
            val food = FoodEntryEntity(
                name = "Unknown",
                entryType = FoodEntryType.FOOD,
                entrySource = FoodEntrySource.USDA
            )

            val result = service.computeEntryNutrition(food, 100.0)

            assertThat(result.calories).isEqualTo(0)
            assertThat(result.proteinG).isEqualTo(0.0)
        }
    }
}
