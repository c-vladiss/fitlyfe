package com.fitlyfe.fitlyfe_backend.api.user.service

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserProfileEntity
import com.fitlyfe.fitlyfe_backend.api.user.repository.UserProfileRepository
import com.fitlyfe.fitlyfe_backend.api.user.repository.UserRepository
import jakarta.persistence.EntityNotFoundException
import org.springframework.stereotype.Service
import java.time.LocalDate
import java.util.UUID

@Service
class UserService(
    private val userRepository: UserRepository,
    private val userProfileRepository: UserProfileRepository,
) {
    /**
     * Upserts a user by their Supabase ID.
     * Returns a Triple of (UserEntity, requiresOnboarding, UserProfileEntity?).
     * requiresOnboarding is true when onboardingCompleted is false.
     */
    fun syncUser(
        supabaseId: UUID,
        email: String,
        firstName: String? = null,
        lastName: String? = null,
    ): Triple<UserEntity, Boolean, UserProfileEntity?> {
        val existing = userRepository.findBySupabaseId(supabaseId)

        val user: UserEntity
        val requiresOnboarding: Boolean

        if (existing != null) {
            val updated = existing.copyForUpdate(
                email = email,
                firstName = firstName ?: existing.firstName,
                lastName = lastName ?: existing.lastName
            )
            user = userRepository.save(updated)
            requiresOnboarding = !existing.onboardingCompleted
        } else {
            val newUser = UserEntity(
                supabaseId = supabaseId,
                email = email,
                firstName = firstName,
                lastName = lastName,
            )
            user = userRepository.save(newUser)
            requiresOnboarding = true
        }

        val profile = userProfileRepository.findByUserId(user.id)
        return Triple(user, requiresOnboarding, profile)
    }

    fun markOnboardingComplete(supabaseId: UUID) {
        val user = userRepository.findBySupabaseId(supabaseId)
            ?: throw EntityNotFoundException("User not found for supabaseId: $supabaseId")
        userRepository.save(user.copyForUpdate(onboardingCompleted = true))
    }

    fun findBySupabaseId(supabaseId: UUID): UserEntity {
        return userRepository.findBySupabaseId(supabaseId)
            ?: throw EntityNotFoundException("User not found for supabaseId: $supabaseId")
    }

    fun upsertProfile(
        userId: UUID,
        displayName: String? = null,
        heightCm: Double? = null,
        weightKg: Double? = null,
        dateOfBirth: LocalDate? = null,
        goal: String? = null,
    ): UserProfileEntity {
        val existing = userProfileRepository.findByUserId(userId)

        val profile = if (existing != null) {
            existing.copyForUpdate(
                displayName = displayName ?: existing.displayName,
                heightCm = heightCm ?: existing.heightCm,
                weightKg = weightKg ?: existing.weightKg,
                dateOfBirth = dateOfBirth ?: existing.dateOfBirth,
                goal = goal ?: existing.goal,
            )
        } else {
            val user = userRepository.findById(userId).orElseThrow {
                EntityNotFoundException("User not found for id: $userId")
            }
            UserProfileEntity(
                userId = userId,
                user = user,
                displayName = displayName,
                heightCm = heightCm,
                weightKg = weightKg,
                dateOfBirth = dateOfBirth,
                goal = goal,
            )
        }

        return userProfileRepository.save(profile)
    }

    fun getProfile(userId: UUID): UserProfileEntity? {
        return userProfileRepository.findByUserId(userId)
    }

    fun getOrCreate(supabaseId: String, email: String): UserEntity {
        val (user, _, _) = syncUser(UUID.fromString(supabaseId), email)
        return user
    }

    fun getUserById(userId: String): UserEntity? {
        return userRepository.findById(UUID.fromString(userId)).orElse(null)
    }
}
