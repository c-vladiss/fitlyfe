package com.fitlyfe.fitlyfe_backend.api.user.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_goals")
data class UserGoalsEntity(
    @Id
    @Column(name = "user_id")
    private val userId: UUID,

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    val user: UserEntity? = null,

    @Column(name = "daily_calories")
    val dailyCalories: Int = 2000,

    @Column(name = "daily_protein_g")
    val dailyProteinG: Double = 150.0,

    @Column(name = "daily_carbs_g")
    val dailyCarbsG: Double = 250.0,

    @Column(name = "daily_fat_g")
    val dailyFatG: Double = 65.0,

    @Column(name = "goal_weight_kg")
    val goalWeightKg: Double? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) : Persistable<UUID> {

    @Transient
    private var _isNew: Boolean = true

    override fun getId(): UUID = userId

    override fun isNew(): Boolean = _isNew

    @PostLoad
    @PostPersist
    fun markNotNew() {
        _isNew = false
    }

    /**
     * Creates a copy for updating an existing entity.
     * Marks the copy as not new so Spring Data calls UPDATE instead of INSERT.
     */
    fun copyForUpdate(
        dailyCalories: Int = this.dailyCalories,
        dailyProteinG: Double = this.dailyProteinG,
        dailyCarbsG: Double = this.dailyCarbsG,
        dailyFatG: Double = this.dailyFatG,
        goalWeightKg: Double? = this.goalWeightKg,
        updatedAt: LocalDateTime = LocalDateTime.now()
    ): UserGoalsEntity {
        return copy(
            dailyCalories = dailyCalories,
            dailyProteinG = dailyProteinG,
            dailyCarbsG = dailyCarbsG,
            dailyFatG = dailyFatG,
            goalWeightKg = goalWeightKg,
            updatedAt = updatedAt
        ).also { it._isNew = false }
    }
}
