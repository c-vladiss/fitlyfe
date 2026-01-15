package com.fitlyfe.fitlyfe_backend.api.nutrition.entity

import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "foods")
data class FoodEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    val name: String? = null,
    val brand: String? = null,

    @Column(name = "calories_per_100g")
    val caloriesPer100g: Int? = null,

    @Column(name = "protein_per_100g")
    val proteinPer100g: Double? = null,

    @Column(name = "carbs_per_100g")
    val carbsPer100g: Double? = null,

    @Column(name = "fat_per_100g")
    val fatPer100g: Double? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
