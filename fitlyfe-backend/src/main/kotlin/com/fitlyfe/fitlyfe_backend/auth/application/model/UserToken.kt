package com.fitlyfe.fitlyfe_backend.auth.application.model

import jakarta.persistence.Id
import java.time.Instant
import java.util.UUID

data class UserToken(
    @Id val userId: UUID,
    var refreshToken: String,
    var keycloakUserId: String,
    var updatedAt: Instant = Instant.now()
)
