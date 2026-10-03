package com.fitlyfe.fitlyfe_backend.api.nutrition.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(
    name = "user_meal_types",
    uniqueConstraints = [UniqueConstraint(columnNames = ["user_id", "name"])]
)
data class UserMealTypeEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: UserEntity,

    @Column(nullable = false, length = 100)
    val name: String,

    @Column(name = "sort_order", nullable = false)
    val sortOrder: Int,

    @Column(name = "is_default", nullable = false)
    val isDefault: Boolean = false,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
