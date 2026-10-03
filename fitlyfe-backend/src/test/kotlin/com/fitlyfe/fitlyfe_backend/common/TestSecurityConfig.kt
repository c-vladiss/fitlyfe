package com.fitlyfe.fitlyfe_backend.common

import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.jwt.JwtDecoder
import org.springframework.security.oauth2.jwt.JwtException
import java.time.Instant
import java.util.UUID

@TestConfiguration
class TestSecurityConfig {

    /**
     * Accepts tokens built by [testToken] and rejects everything else, so tests
     * can act as any user without a real Supabase JWKS endpoint.
     */
    @Bean
    fun jwtDecoder(): JwtDecoder = JwtDecoder { token ->
        val supabaseId = token.removePrefix(TOKEN_PREFIX)
        if (!token.startsWith(TOKEN_PREFIX) || runCatching { UUID.fromString(supabaseId) }.isFailure) {
            throw JwtException("Invalid token for testing")
        }
        Jwt.withTokenValue(token)
            .header("alg", "none")
            .subject(supabaseId)
            .claim("email", testEmail(UUID.fromString(supabaseId)))
            .issuedAt(Instant.now())
            .expiresAt(Instant.now().plusSeconds(3600))
            .build()
    }

    companion object {
        // Bearer tokens may only contain [A-Za-z0-9-._~+/], so the email is derived, not embedded
        private const val TOKEN_PREFIX = "test."

        fun testToken(supabaseId: UUID) = "$TOKEN_PREFIX$supabaseId"

        fun testEmail(supabaseId: UUID) = "$supabaseId@test.fitlyfe"
    }
}
