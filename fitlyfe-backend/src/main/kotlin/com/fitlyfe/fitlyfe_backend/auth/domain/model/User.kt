package com.fitlyfe.fitlyfe_backend.auth.domain.model


import java.time.Instant
import java.util.UUID

data class User(
    val userId: UUID? = null,
    val email: String,
    val firstName: String,
    val lastName: String,
    val hashedPassword: String?,
    val authProvider: AuthProvider,
    val userType: UserType,
    val createdAt: Instant = Instant.now(),
)
