package com.fitlyfe.fitlyfe_backend.api.user.entity

import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_profiles")
data class UserProfileEntity(
    @Id
    @Column(name = "user_id")
    val userId: UUID,

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

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
