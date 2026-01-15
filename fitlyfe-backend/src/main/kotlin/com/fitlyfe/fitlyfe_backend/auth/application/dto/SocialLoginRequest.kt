package com.fitlyfe.fitlyfe_backend.auth.application.dto

data class SocialLoginRequest(
    val provider: String,
    val codeChallenge: String,
    val state: String
)
