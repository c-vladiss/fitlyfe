package com.fitlyfe.fitlyfe_backend.api.user.entity

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "users")
data class UserEntity(
    @Id
    @Column(name = "user_id", unique = true, nullable = false)
    private val id: UUID = UUID.randomUUID(),

    @Column(name = "supabase_id", unique = true, nullable = false)
    val supabaseId: UUID,

    @Column(name = "email", nullable = false)
    val email: String,

    @Column(name = "first_name")
    val firstName: String? = null,

    @Column(name = "last_name")
    val lastName: String? = null,

    @Column(name = "onboarding_completed", nullable = false)
    val onboardingCompleted: Boolean = false,

    @Column(name = "status")
    val status: String = "ACTIVE",

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
) : Persistable<UUID> {

    @Transient
    private var _isNew: Boolean = true

    override fun getId(): UUID = id

    override fun isNew(): Boolean = _isNew

    @PostLoad
    @PostPersist
    fun markNotNew() {
        _isNew = false
    }

    /**
     * Creates a copy for updating an existing entity.
     * Preserves the ID and marks the copy as not new (for UPDATE instead of INSERT).
     */
    fun copyForUpdate(
        email: String = this.email,
        firstName: String? = this.firstName,
        lastName: String? = this.lastName,
        onboardingCompleted: Boolean = this.onboardingCompleted,
        status: String = this.status,
        updatedAt: LocalDateTime = LocalDateTime.now()
    ): UserEntity {
        return copy(
            id = this.id,
            email = email,
            firstName = firstName,
            lastName = lastName,
            onboardingCompleted = onboardingCompleted,
            status = status,
            updatedAt = updatedAt
        ).also { it._isNew = false }
    }
}
