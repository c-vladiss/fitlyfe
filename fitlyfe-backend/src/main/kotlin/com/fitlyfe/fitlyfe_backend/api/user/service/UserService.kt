package com.fitlyfe.fitlyfe_backend.api.user.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.repository.UserRepository
import jakarta.persistence.EntityNotFoundException
import org.springframework.stereotype.Service
import java.util.UUID

@Service
class UserService(
    private val userRepository: UserRepository,
) {
    /**
     * Upserts a user by their Supabase ID.
     * Returns a Pair of (UserEntity, requiresOnboarding).
     * requiresOnboarding is true when onboardingCompleted is false.
     */
    fun syncUser(
        supabaseId: UUID,
        email: String,
        firstName: String? = null,
        lastName: String? = null,
    ): Pair<UserEntity, Boolean> {
        val existing = userRepository.findBySupabaseId(supabaseId)

        if (existing != null) {
            val updated = existing.copyForUpdate(
                email = email,
                firstName = firstName ?: existing.firstName,
                lastName = lastName ?: existing.lastName
            )
            return Pair(userRepository.save(updated), !existing.onboardingCompleted)
        }

        val newUser = UserEntity(
            supabaseId = supabaseId,
            email = email,
            firstName = firstName,
            lastName = lastName,
        )
        return Pair(userRepository.save(newUser), true)
    }

    fun markOnboardingComplete(supabaseId: UUID) {
        val user = userRepository.findBySupabaseId(supabaseId)
            ?: throw EntityNotFoundException("User not found for supabaseId: $supabaseId")
        userRepository.save(user.copyForUpdate(onboardingCompleted = true))
    }

    fun getOrCreate(supabaseId: String, email: String): UserEntity {
        val (user, _) = syncUser(UUID.fromString(supabaseId), email)
        return user
    }

    fun getUserById(userId: String): UserEntity? {
        return userRepository.findById(UUID.fromString(userId)).orElse(null)
    }
}
