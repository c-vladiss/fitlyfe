package com.fitlyfe.fitlyfe_backend.auth.application.dto

import com.fasterxml.jackson.annotation.JsonProperty

data class AuthResponse(
    @param:JsonProperty("access_token") val accessToken: String,
    @param:JsonProperty("refresh_token") val refreshToken: String,
    @param:JsonProperty("expires_in") val expiresIn: Long,
    @param:JsonProperty("refresh_expires_in") val refreshExpiresIn: Long,
    @param:JsonProperty("token_type") val tokenType: String,
    @param:JsonProperty("id_token") val tokenId: String?,
    @param:JsonProperty("session_state") val sessionState: String?,
    @param:JsonProperty("scope") val scope: String?,

    val provider: String = "Fitlyfe"
)
