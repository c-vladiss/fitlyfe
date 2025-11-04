package com.fitlyfe.fitlyfe_backend.auth.domain.service

import com.fitlyfe.fitlyfe_backend.auth.domain.model.UserType
import com.fitlyfe.fitlyfe_backend.auth.domain.model.User
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service

@Service
class AuthDomainService(private val passwordEncoder: PasswordEncoder) {
    fun hashPassword(password: String): String = passwordEncoder.encode(password)
    fun isPasswordValid(rawPassword: String, encodedPassword: String): Boolean = passwordEncoder.matches(rawPassword, encodedPassword)
    fun assignDefaultRole(user: User) = user.copy(userType = UserType.BASIC)
}