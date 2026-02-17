package com.fitlyfe.fitlyfe_backend.common

import org.springframework.boot.test.context.TestConfiguration
import org.springframework.context.annotation.Bean
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.jwt.JwtDecoder
import java.time.Instant

@TestConfiguration
class TestSecurityConfig {

    @Bean
    fun jwtDecoder(): JwtDecoder {
        // Return a mock JWT decoder that rejects all tokens (simulating unauthenticated access)
        // For authenticated test scenarios, use @WithMockUser or create valid test tokens
        return JwtDecoder { token ->
            throw org.springframework.security.oauth2.jwt.JwtException("Invalid token for testing")
        }
    }
}
