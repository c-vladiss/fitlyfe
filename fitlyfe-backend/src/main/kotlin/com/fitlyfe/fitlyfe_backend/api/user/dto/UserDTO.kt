package com.fitlyfe.fitlyfe_backend.api.user.dto

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import java.util.UUID

data class UserDTO(
    val userId: UUID,
    val email: String,
    val displayName: String?
) {
    companion object {
        fun fromEntity(user: UserEntity): UserDTO {
            return UserDTO(
                userId = user.keycloakSub,
                email = user.email,
                displayName = user.displayName
            )
        }
    }
}
