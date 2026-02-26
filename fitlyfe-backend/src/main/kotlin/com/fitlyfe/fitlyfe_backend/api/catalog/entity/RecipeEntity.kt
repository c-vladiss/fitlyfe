package com.fitlyfe.fitlyfe_backend.api.catalog.entity

import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "recipes")
data class RecipeEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_entry_id", nullable = false, unique = true)
    val foodEntry: FoodEntryEntity,

    @Column(nullable = false)
    val servings: Int = 1,

    @Column(name = "serving_label", length = 50)
    val servingLabel: String? = null,

    @Column(name = "prep_time_min")
    val prepTimeMin: Int? = null,

    @Column(name = "cook_time_min")
    val cookTimeMin: Int? = null,

    @Column(columnDefinition = "TEXT")
    val instructions: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
