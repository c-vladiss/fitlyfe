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
        val keycloakSub: UUID = UUID.fromString(keycloakId)
        val existing = userRepository.findById(keycloakSub)
        if(existing.isPresent) return existing.get()

        val newUser = UserEntity(
            keycloakSub = keycloakSub,
            userId = UUID.randomUUID(),
            email = email,
            displayName = email
        )

        return userRepository.save(newUser)
    }

    fun getUserById(userId: String): UserEntity {
        return userRepository.findById(UUID.fromString(userId)).orElse(null)
    }
}