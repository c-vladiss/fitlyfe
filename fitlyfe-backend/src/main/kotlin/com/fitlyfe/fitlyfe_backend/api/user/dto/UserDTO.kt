package com.fitlyfe.fitlyfe_backend.api.user.dto

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import java.util.UUID

data class UserDTO(
    val userId: UUID,
    val email: String,
    val displayName: String? = null
) {
    companion object {
        fun fromEntity(user: UserEntity): UserDTO {
            return UserDTO(
                userId = user.id,
                email = user.email,
                displayName = null // Display name is now in UserProfileEntity
            )
        }
    }
}
