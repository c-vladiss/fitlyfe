package com.fitlyfe.fitlyfe_backend.auth.application.dto

import com.fitlyfe.fitlyfe_backend.auth.domain.model.UserType

data class UserResponse(
    val email: String,
    val firstName: String,
    val lastName: String,
    val userType: UserType,
)
