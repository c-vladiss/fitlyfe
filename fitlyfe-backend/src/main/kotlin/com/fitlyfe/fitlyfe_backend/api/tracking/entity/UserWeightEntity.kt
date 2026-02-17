package com.fitlyfe.fitlyfe_backend.api.tracking.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_weights")
data class UserWeightEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    @Column(name = "measured_at", nullable = false)
    val measuredAt: LocalDateTime,

    @Column(name = "weight_kg")
    val weightKg: Double? = null,

    val source: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now()
)
