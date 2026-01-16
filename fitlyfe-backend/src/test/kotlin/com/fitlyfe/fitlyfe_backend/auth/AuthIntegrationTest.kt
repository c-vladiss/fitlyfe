package com.fitlyfe.fitlyfe_backend.auth

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.web.client.TestRestTemplate
import org.springframework.http.HttpStatus

class AuthIntegrationTest : AbstractIntegrationTest() {

    @Autowired
    lateinit var restTemplate: TestRestTemplate

    @Test
    fun `should register and login user successfully`() {
        // 1. Register
        val registerRequest = RegisterRequest(
            email = "newuser@test.com",
            password = "password",
            firstName = "John",
            lastName = "Doe",
            provider = "email"
        )

        val registerResponse = restTemplate.postForEntity(
            "/api/auth/register",
            registerRequest,
            AuthResponse::class.java
        )

        // Note: If role mapping for service account is missing, this might fail with 403 or 401 from KeycloakClient
        assertEquals(HttpStatus.OK, registerResponse.statusCode, "Registration should succeed")
        assertNotNull(registerResponse.body?.accessToken)
        assertEquals("newuser@test.com", userRepository.findByEmail("newuser@test.com")?.email)


        // 2. Login
        val loginRequest = LoginRequest(
            email = "newuser@test.com",
            password = "password",
            provider = "email"
        )

        val loginResponse = restTemplate.postForEntity(
            "/api/auth/login",
            loginRequest,
            AuthResponse::class.java
        )

        assertEquals(HttpStatus.OK, loginResponse.statusCode, "Login should succeed")
        assertNotNull(loginResponse.body?.accessToken)
    }

    @Autowired
    lateinit var userRepository: com.fitlyfe.fitlyfe_backend.api.user.repository.UserRepository
}
