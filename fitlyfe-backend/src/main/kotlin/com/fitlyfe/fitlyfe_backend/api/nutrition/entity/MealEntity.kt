package com.fitlyfe.fitlyfe_backend.api.nutrition.entity

import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "meals")
data class MealEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "daily_nutrition_id")
    val dailyNutrition: DailyNutritionEntity,

    @Column(name = "meal_type")
    val mealType: String? = null,

    @Column(name = "logged_at")
    val loggedAt: LocalDateTime? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now()
)
