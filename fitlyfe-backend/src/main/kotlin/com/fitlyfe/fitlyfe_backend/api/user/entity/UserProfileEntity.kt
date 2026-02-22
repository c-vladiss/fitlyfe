package com.fitlyfe.fitlyfe_backend.api.user.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_profiles")
data class UserProfileEntity(
    @Id
    @Column(name = "user_id")
    private val userId: UUID,

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    val user: UserEntity? = null,

    @Column(name = "first_name")
    val firstName: String? = null,

    @Column(name = "last_name")
    val lastName: String? = null,

    @Column(name = "display_name")
    val displayName: String? = null,

    val phone: String? = null,
    val gender: String? = null,

    @Column(name = "date_of_birth")
    val dateOfBirth: LocalDate? = null,

    @Column(name = "height_cm")
    val heightCm: Double? = null,

    @Column(name = "weight_kg")
    val weightKg: Double? = null,

    @Column(name = "goal")
    val goal: String? = null,

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
        displayName: String? = this.displayName,
        heightCm: Double? = this.heightCm,
        weightKg: Double? = this.weightKg,
        dateOfBirth: LocalDate? = this.dateOfBirth,
        goal: String? = this.goal,
        updatedAt: LocalDateTime = LocalDateTime.now()
    ): UserProfileEntity {
        return copy(
            displayName = displayName,
            heightCm = heightCm,
            weightKg = weightKg,
            dateOfBirth = dateOfBirth,
            goal = goal,
            updatedAt = updatedAt
        ).also { it._isNew = false }
    }
}
