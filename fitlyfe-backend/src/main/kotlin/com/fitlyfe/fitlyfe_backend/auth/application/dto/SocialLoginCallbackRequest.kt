package com.fitlyfe.fitlyfe_backend.auth.application.dto

data class SocialLoginCallbackRequest(
    val code: String,
    val codeVerifier: String
)
