package com.fitlyfe.fitlyfe_backend.api.nutrition.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "daily_nutrition")
data class DailyNutritionEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    @Column(nullable = false)
    val date: java.time.LocalDate,

    @Column(name = "total_calories")
    val totalCalories: Int? = null,

    @Column(name = "protein_g")
    val proteinG: Double? = null,

    @Column(name = "carbs_g")
    val carbsG: Double? = null,

    @Column(name = "fat_g")
    val fatG: Double? = null,

    @Column(name = "water_ml")
    val waterMl: Int? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
