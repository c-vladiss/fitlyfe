package com.fitlyfe.fitlyfe_backend.auth.application.dto

data class TokenResponse(
    val accessToken: String,
    val tokenType: String = "Bearer"
)
