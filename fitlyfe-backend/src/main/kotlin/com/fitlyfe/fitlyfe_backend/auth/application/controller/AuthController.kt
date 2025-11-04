package com.fitlyfe.fitlyfe_backend.auth.application.controller

import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.TokenResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.UserResponse
import com.fitlyfe.fitlyfe_backend.auth.application.service.AuthService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/auth")
class AuthController(
    private val authService: AuthService,
) {
    @PostMapping("/register")
    fun userRegister(@Valid @RequestBody request: RegisterRequest): ResponseEntity<UserResponse> =
        ResponseEntity.ok(authService.userRegister(request))

    @PostMapping("/login")
    fun userLogin(@Valid @RequestBody request: LoginRequest): ResponseEntity<TokenResponse> =
        ResponseEntity.ok(authService.userLogin(request))
}