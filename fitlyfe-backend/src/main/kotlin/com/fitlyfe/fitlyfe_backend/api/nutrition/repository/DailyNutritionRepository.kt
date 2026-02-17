package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.DailyNutritionEntity
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.time.LocalDate
import java.util.UUID

interface DailyNutritionRepository : JpaRepository<DailyNutritionEntity, UUID> {
    fun findByUserAndDate(user: UserEntity, date: LocalDate): DailyNutritionEntity?
}
