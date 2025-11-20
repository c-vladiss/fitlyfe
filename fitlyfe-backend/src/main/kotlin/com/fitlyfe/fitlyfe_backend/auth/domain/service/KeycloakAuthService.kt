package com.fitlyfe.fitlyfe_backend.auth.domain.service

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RedirectResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RefreshRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginRequest
import com.fitlyfe.fitlyfe_backend.auth.domain.exception.*
import com.fitlyfe.fitlyfe_backend.auth.infrastructure.keycloak.KeycloakClient
import org.springframework.stereotype.Service
import org.springframework.web.client.HttpClientErrorException

@Service
class KeycloakAuthService(
    private val keycloakClient: KeycloakClient
) {
    fun register(request: RegisterRequest): AuthResponse {
        try {
            keycloakClient.createUser(request.firstName, request.lastName, request.email, request.password)
            val tokenResponse = keycloakClient.login(request.email, request.password)
            return toAuthResponse(tokenResponse, provider = request.provider)
        } catch (ex: HttpClientErrorException.Conflict) {
            throw UserAlreadyExistsException("Email or username already in use: ${ex.message}")
        } catch (ex: HttpClientErrorException.BadRequest) {
            throw InvalidCredentialsException("Invalid request data: ${ex.message}")
        } catch (ex: Exception) {
            throw KeycloakServiceException("Unexpected Keycloak error: ${ex.message}")
        }
    }

    fun login(request: LoginRequest): AuthResponse {
        try {
            val tokenResponse = keycloakClient.login(request.email, request.password)
            return toAuthResponse(tokenResponse, provider = request.provider)
        } catch (ex: HttpClientErrorException.Conflict) {
            throw UserAlreadyExistsException("Email or username already in use: ${ex.message}")
        } catch (ex: HttpClientErrorException.BadRequest) {
            throw InvalidCredentialsException("Invalid request data: ${ex.message}")
        } catch (ex: Exception) {
            throw KeycloakServiceException("Unexpected Keycloak error: ${ex.message}")
        }

    }

    fun refresh(request: RefreshRequest): AuthResponse =
        keycloakClient.refreshToken(request.refreshToken)


    fun socialLogin(request: SocialLoginRequest): RedirectResponse {
        val redirectUri = keycloakClient.getSocialLoginRedirect(request)
        return RedirectResponse( redirectUri = redirectUri )
    }

    fun socialLoginCallback(code: String): AuthResponse =
        keycloakClient.exchangeCodeForToken(code)

    private fun toAuthResponse(map: Map<*, *>, provider: String): AuthResponse {
        fun <T> get(key: String): T = map[key] as T

        return AuthResponse(
            accessToken = get("access_token"),
            refreshToken = get("refresh_token"),
            expiresIn = (get<Number>("expires_in")).toLong(),
            refreshExpiresIn = (get<Number>("refresh_expires_in")).toLong(),
            tokenType = get("token_type"),
            tokenId = map["id_token"] as String?,
            sessionState = map["session_state"] as String?,
            scope = map["scope"] as String?,
            provider = provider
        )
    }

}