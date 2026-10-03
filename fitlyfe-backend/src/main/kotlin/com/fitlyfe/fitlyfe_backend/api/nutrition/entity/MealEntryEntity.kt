package com.fitlyfe.fitlyfe_backend.api.nutrition.entity

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import jakarta.persistence.*
import java.util.UUID

@Entity
@Table(name = "meal_entries")
data class MealEntryEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "meal_id", nullable = false)
    val meal: MealEntity,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_entry_id", nullable = false)
    val foodEntry: FoodEntryEntity,

    @Column(name = "quantity_g")
    val quantityG: Double? = null,

    val calories: Int? = null,

    @Column(name = "protein_g")
    val proteinG: Double? = null,

    @Column(name = "carbs_g")
    val carbsG: Double? = null,

    @Column(name = "fat_g")
    val fatG: Double? = null
)
