package com.fitlyfe.fitlyfe_backend.api.catalog.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "food_entries")
data class FoodEntryEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false, length = 500)
    val name: String,

    @Column(length = 255)
    val brand: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "entry_type", nullable = false, length = 20)
    val entryType: FoodEntryType,

    @Column(length = 50)
    val barcode: String? = null,

    @Column(name = "serving_size_g")
    val servingSizeG: Double? = null,

    // Macronutrients (per 100 g)
    @Column(name = "calories_per_100g")
    val caloriesPer100g: Double? = null,

    @Column(name = "protein_per_100g")
    val proteinPer100g: Double? = null,

    @Column(name = "carbs_per_100g")
    val carbsPer100g: Double? = null,

    @Column(name = "fat_per_100g")
    val fatPer100g: Double? = null,

    @Column(name = "fiber_per_100g")
    val fiberPer100g: Double? = null,

    @Column(name = "sugar_per_100g")
    val sugarPer100g: Double? = null,

    @Column(name = "saturated_fat_per_100g")
    val saturatedFatPer100g: Double? = null,

    // Micronutrients (JSONB)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    val micronutrients: Micronutrients? = null,

    // Provenance
    @Enumerated(EnumType.STRING)
    @Column(name = "entry_source", nullable = false, length = 30)
    val entrySource: FoodEntrySource,

    @Column(name = "external_id", length = 100)
    val externalId: String? = null,

    @Column(nullable = false)
    val verified: Boolean = false,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    val createdBy: UserEntity? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
