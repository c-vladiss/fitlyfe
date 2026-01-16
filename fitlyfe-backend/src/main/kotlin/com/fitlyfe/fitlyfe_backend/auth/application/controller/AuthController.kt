package com.fitlyfe.fitlyfe_backend.auth.application.controller

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LogoutResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RedirectResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RefreshRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginCallbackRequest
import com.fitlyfe.fitlyfe_backend.auth.application.service.AuthService
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/auth")
class AuthController(
    private val authService: AuthService,
) {
    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest): ResponseEntity<AuthResponse> =
        ResponseEntity.ok(authService.register(request))

    @PostMapping("/login")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<AuthResponse> =
        ResponseEntity.ok(authService.login(request))

    @PostMapping("/refresh")
    fun refresh(@Valid @RequestBody request: RefreshRequest) : ResponseEntity<AuthResponse> =
        ResponseEntity.ok(authService.refresh(request))

    @PostMapping("/social-login")
    fun socialLogin(@Valid @RequestBody request: SocialLoginRequest): ResponseEntity<RedirectResponse> =
        ResponseEntity.ok(authService.socialLogin(request))

    @PostMapping("/social-login/callback")
    fun socialLoginCallBack(@Valid @RequestBody request: SocialLoginCallbackRequest): ResponseEntity<AuthResponse> =
        ResponseEntity.ok(authService.socialLoginCallback(request))

    @PostMapping("/logout")
    fun logout(@Valid @RequestBody refreshToken: String): ResponseEntity<LogoutResponse> =
        ResponseEntity.ok(authService.logout(refreshToken))

}