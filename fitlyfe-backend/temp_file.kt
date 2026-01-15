package com.fitlyfe.fitlyfe_backend.auth.domain.service

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LogoutResponse
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
    private val keycloakClient: KeycloakClient,
    private val userService: UserService,
    private val objectMapper: ObjectMapper
) {
    fun register(request: RegisterRequest): AuthResponse {
        try {
            keycloakClient.createUser(request.firstName, request.lastName, request.email, request.password)
            val tokenResponse = keycloakClient.login(request.email, request.password)
            val response = toAuthResponse(tokenResponse, provider = request.provider)
            syncUser(response.accessToken, request.email)
            return response
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
            val response = toAuthResponse(tokenResponse, provider = request.provider)
            syncUser(response.accessToken, request.email)
            return response
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

    fun socialLoginCallback(code: String): AuthResponse {
        val response = keycloakClient.exchangeCodeForToken(code)
        // Best effort sync for social login - email might be in token
        try {
             val claims = decodeToken(response.accessToken)
             val email = claims["email"] as? String ?: ""
             if (email.isNotEmpty()) {
                 syncUser(response.accessToken, email)
             }
        } catch (e: Exception) {
            // Log error but don't fail login
        }
        return response
    }
    
    fun logout(token: String): LogoutResponse =
        keycloakClient.logout(token)

    private fun syncUser(accessToken: String, email: String) {
        try {
            val claims = decodeToken(accessToken)
            val sub = claims["sub"] as? String ?: throw IllegalStateException("No 'sub' claim in token")
            userService.getOrCreate(sub, email)
        } catch (e: Exception) {
             throw KeycloakServiceException("Failed to sync user to local DB: ${e.message}")
        }
    }

    private fun decodeToken(token: String): Map<String, Any> {
        val parts = token.split(".")
        if (parts.size < 2) throw IllegalArgumentException("Invalid JWT token")
        val payload = String(java.util.Base64.getUrlDecoder().decode(parts[1]))
        return objectMapper.readValue(payload, Map::class.java) as Map<String, Any>
    }

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