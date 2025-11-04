package com.fitlyfe.fitlyfe_backend.auth.application.dto

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size

data class RegisterRequest(
    @field:Email val email: String,
    @field:NotBlank @field:Size(min = 6) val password: String,
    @field:NotBlank val firstName: String,
    @field:NotBlank val lastName: String,

)
