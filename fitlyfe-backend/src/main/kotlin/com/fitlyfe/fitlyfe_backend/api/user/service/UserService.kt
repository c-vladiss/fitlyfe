package com.fitlyfe.fitlyfe_backend.api.user.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.repository.UserRepository
import org.springframework.stereotype.Service
import java.util.UUID

@Service
class UserService(
    private val userRepository: UserRepository,
) {
    fun getOrCreate(keycloakId: String, email: String): UserEntity {
        val kId: UUID = UUID.fromString(keycloakId)
        val existing = userRepository.findByKeycloakId(kId)
        
        if (existing != null) {
            if (existing.email != email) {
                val updated = existing.copy(email = email, updatedAt = java.time.LocalDateTime.now())
                return userRepository.save(updated)
            }
            return existing
        }

        val newUser = UserEntity(
            keycloakId = kId,
            email = email
        )

        return userRepository.save(newUser)
    }

    fun getUserById(userId: String): UserEntity? {
        return userRepository.findById(UUID.fromString(userId)).orElse(null)
    }
}