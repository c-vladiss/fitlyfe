package com.fitlyfe.fitlyfe_backend.auth.application.dto

data class ApiAuthError(
    val errorCode: String,
    val errorMessage: String,
    val timestamp: String = java.time.Instant.now().toString()
)
