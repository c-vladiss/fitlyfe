package com.fitlyfe.fitlyfe_backend.auth.application.service

import com.fitlyfe.fitlyfe_backend.auth.application.dto.AuthResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.LogoutResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RedirectResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RefreshRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.SocialLoginCallbackRequest
import com.fitlyfe.fitlyfe_backend.auth.domain.service.KeycloakAuthService
import org.springframework.stereotype.Service

@Service
class AuthService(
    private val keycloakAuthService: KeycloakAuthService
) {
    fun register(request: RegisterRequest): AuthResponse =
        keycloakAuthService.register(request)
    fun login(request: LoginRequest): AuthResponse =
        keycloakAuthService.login(request)
    fun refresh(request: RefreshRequest): AuthResponse=
        keycloakAuthService.refresh(request)
    fun socialLogin(request: SocialLoginRequest): RedirectResponse =
        keycloakAuthService.socialLogin(request)
    fun socialLoginCallback(request: SocialLoginCallbackRequest): AuthResponse =
        keycloakAuthService.socialLoginCallback(request)
    fun logout(token: String): LogoutResponse =
        keycloakAuthService.logout(token)
}
