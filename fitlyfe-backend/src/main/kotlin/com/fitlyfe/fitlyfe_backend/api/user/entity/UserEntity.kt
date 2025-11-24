package com.fitlyfe.fitlyfe_backend.api.user.entity

import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.util.UUID

@Entity
@Table(name = "users")
data class UserEntity(
    @Id
    val userId: UUID,
    val keycloakSub: UUID,
    val email: String,
    val displayName: String,
    val createdAt: Long = System.currentTimeMillis()
)
