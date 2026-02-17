package com.fitlyfe.fitlyfe_backend.api.tracking.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "daily_steps")
data class DailyStepEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    val date: java.time.LocalDate? = null,
    val steps: Int? = null,
    val source: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now()
)
