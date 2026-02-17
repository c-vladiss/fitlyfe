package com.fitlyfe.fitlyfe_backend.api.tracking.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_measurements")
data class UserMeasurementEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    @Column(name = "measured_at", nullable = false)
    val measuredAt: LocalDateTime,

    @Column(name = "waist_cm")
    val waistCm: Double? = null,

    @Column(name = "neck_cm")
    val neckCm: Double? = null,

    @Column(name = "chest_cm")
    val chestCm: Double? = null,

    @Column(name = "hip_cm")
    val hipCm: Double? = null,

    @Column(name = "arm_cm")
    val armCm: Double? = null,

    @Column(name = "thigh_cm")
    val thighCm: Double? = null,

    @Column(name = "body_fat_pct")
    val bodyFatPct: Double? = null,

    val notes: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now()
)
