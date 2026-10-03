package com.fitlyfe.fitlyfe_backend.api.catalog.entity

import jakarta.persistence.*
import java.util.UUID

@Entity
@Table(name = "recipe_ingredients")
data class RecipeIngredientEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipe_id", nullable = false)
    val recipe: RecipeEntity,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_entry_id", nullable = false)
    val foodEntry: FoodEntryEntity,

    @Column(name = "quantity_g", nullable = false)
    val quantityG: Double,

    @Column(name = "display_amount", nullable = false)
    val displayAmount: Double,

    @Column(name = "display_unit", nullable = false, length = 30)
    val displayUnit: String,

    @Column(name = "order_index", nullable = false)
    val orderIndex: Int = 0,

    @Column(length = 255)
    val notes: String? = null
)
