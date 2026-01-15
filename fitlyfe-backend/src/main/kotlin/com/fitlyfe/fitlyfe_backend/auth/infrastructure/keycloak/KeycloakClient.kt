package com.fitlyfe.fitlyfe_backend.auth.infrastructure.keycloak

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LogoutResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginRequest
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.*
import org.springframework.stereotype.Component
import org.springframework.util.LinkedMultiValueMap
import org.springframework.web.client.RestTemplate
import org.springframework.web.client.exchange
import org.springframework.web.util.UriComponentsBuilder
import java.net.URI
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

@Component
class KeycloakClient (
    @Value("\${keycloak.server-url}")
    private val keycloakServerUrl: String,
    @Value("\${keycloak.realm}")
    private val keycloakRealm: String,
    @Value("\${keycloak.admin-client-id}")
    private val keycloakClientId: String,
    @Value("\${keycloak.client-secret}")
    private val clientSecret: String,
    @Value("\${keycloak.mobile-callback-uri}")
    private val mobileCallbackUri: String,
) {
    private val rest = RestTemplate()

    fun createUser(firstName: String, lastName: String, email: String, password: String) {
        val token = getAdminToken()
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_JSON
            setBearerAuth(token)
        }

        val body = mapOf(
            "firstName" to firstName,
            "lastName" to lastName,
            "username" to email,
            "email" to email,
            "enabled" to true,
            "credentials" to listOf(
                mapOf("type" to "password", "value" to password, "temporary" to false)
            )
        )

        val url = "$keycloakServerUrl/admin/realms/$keycloakRealm/users"
        val request = RequestEntity.post(URI(url))
            .headers(headers)
            .body(body)

        rest.exchange<Unit>(request)
    }

    fun login(username: String, password: String): Map<*, *> {
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_FORM_URLENCODED
        }
        val body = LinkedMultiValueMap<String, String>().apply {
            add("grant_type", "password")
            add("client_id", keycloakClientId)
            add("client_secret", clientSecret)
            add("username", username)
            add("password", password)
        }

        val entity = HttpEntity(body, headers)
        val response = rest.postForEntity("$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/token", entity, Map::class.java)

        val bodyMap = response.body as Map<*, *>
        return bodyMap
    }

    fun getSocialLoginRedirect(request: SocialLoginRequest): String {
        val realmUrl = "$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/auth"
        val scope = URLEncoder.encode("openid profile email", StandardCharsets.UTF_8.toString())
        val callbackUrl = URLEncoder.encode(mobileCallbackUri, StandardCharsets.UTF_8.toString())

        val params = UriComponentsBuilder.fromUriString(realmUrl)
            .queryParam("client_id", keycloakClientId)
            .queryParam("redirect_uri", callbackUrl)
            .queryParam("response_type", "code")
            .queryParam("scope", scope)
            .queryParam("kc_idp_hint", request.provider)
            .queryParam("code_challenge", request.codeChallenge)
            .queryParam("code_challenge_method", "S256")
            .queryParam("state", request.state)
            .build()
            .toUriString()
        return params
    }

    fun exchangeCodeForToken(code: String, codeVerifier: String): AuthResponse {
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_FORM_URLENCODED
        }
        val body = LinkedMultiValueMap<String, String>().apply {
            add("grant_type", "authorization_code")
            add("client_id", keycloakClientId)
            add("client_secret", clientSecret)
            add("code", code)
            add("redirect_uri", mobileCallbackUri)
            add("code_verifier", codeVerifier)
        }

        val entity = HttpEntity(body, headers)
        val response = rest.postForEntity(
            "$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/token",
            entity,
            AuthResponse::class.java
        )
        val authResponse: AuthResponse = response.body as AuthResponse
        return authResponse
    }

    private fun getAdminToken(): String {
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_FORM_URLENCODED
        }

        val body = LinkedMultiValueMap<String, String>().apply {
            add("grant_type", "client_credentials")
            add("client_id", keycloakClientId)
            add("client_secret", clientSecret)
        }

        val entity = HttpEntity(body, headers)
        val response = rest.postForEntity(
            "$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/token",
            entity,
            Map::class.java
        )
        val bodyMap = response.body as Map<*, *>
        return bodyMap["access_token"] as String
    }

    fun refreshToken(refreshToken: String): AuthResponse {
        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_FORM_URLENCODED
        }
        val body = LinkedMultiValueMap<String, String>().apply {
            add("grant_type", "refresh_token")
            add("client_id", keycloakClientId)
            add("client_secret", clientSecret)
            add("refresh_token", refreshToken)
        }

        val entity = HttpEntity(body, headers)
        val response = rest.postForEntity(
            "$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/token",
            entity,
            AuthResponse::class.java
        )
        val authResponse: AuthResponse = response.body as AuthResponse
        return authResponse
    }

    fun logout(refreshToken: String): LogoutResponse {
        val logoutUrl = "$keycloakServerUrl/realms/$keycloakRealm/protocol/openid-connect/logout"

        val body = LinkedMultiValueMap<String, String>().apply {
            add("client_id", keycloakClientId)
            add("client_secret", clientSecret)
            add("refresh_token", refreshToken)
        }

        val headers = HttpHeaders().apply {
            contentType = MediaType.APPLICATION_FORM_URLENCODED
        }

        val request = HttpEntity(body, headers)

        val response = rest.postForEntity(logoutUrl, request, LogoutResponse::class.java)

        if (!response.statusCode.is2xxSuccessful) {
            throw RuntimeException("Failed to logout from Keycloak: ${response.statusCode}")
        }
        val logoutResponse: LogoutResponse = response.body as LogoutResponse
        return logoutResponse
    }
}