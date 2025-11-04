package com.fitlyfe.fitlyfe_backend.auth.application.service

import com.fitlyfe.fitlyfe_backend.auth.application.dto.LoginRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.RegisterRequest
import com.fitlyfe.fitlyfe_backend.auth.application.dto.TokenResponse
import com.fitlyfe.fitlyfe_backend.auth.application.dto.UserResponse
import com.fitlyfe.fitlyfe_backend.auth.domain.model.AuthProvider
import com.fitlyfe.fitlyfe_backend.auth.domain.model.User
import com.fitlyfe.fitlyfe_backend.auth.domain.model.UserType
import com.fitlyfe.fitlyfe_backend.auth.infrastructure.repository.UserRepository
import com.fitlyfe.fitlyfe_backend.auth.domain.service.AuthDomainService
import com.fitlyfe.fitlyfe_backend.auth.infrastructure.security.JwtProvider
import org.springframework.stereotype.Service

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val domainService: AuthDomainService,
    private val jwtProvider: JwtProvider
) {
    fun userLogin(request: LoginRequest): TokenResponse {
        val user = userRepository.findUserByEmail(request.email)
            ?: throw IllegalArgumentException("Invalid credentials")
        if(!domainService.isPasswordValid(request.password, user.hashedPassword?: ""))
            throw IllegalArgumentException("Invalid credentials")

        val jwtToken = jwtProvider.generateToken(user.email)
        return TokenResponse(jwtToken)
    }

    fun userRegister(request: RegisterRequest): UserResponse {
        if(userRepository.findUserByEmail(request.email) != null)
            throw IllegalArgumentException("Email already exists")

        val hashedPassword: String = domainService.hashPassword(request.password)
        val user = User(
            email = request.email,
            hashedPassword = hashedPassword,
            firstName = request.firstName,
            lastName = request.lastName,
            authProvider = AuthProvider.LOCAL,
            userType = UserType.BASIC,
        )

        val savedUser = userRepository.saveUser(domainService.assignDefaultRole(user))
        return UserResponse(savedUser.email, savedUser.firstName, savedUser.lastName, savedUser.userType)
    }
}