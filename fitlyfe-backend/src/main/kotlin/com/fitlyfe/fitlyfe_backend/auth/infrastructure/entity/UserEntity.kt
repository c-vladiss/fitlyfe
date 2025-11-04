package com.fitlyfe.fitlyfe_backend.auth.infrastructure.entity

import com.fitlyfe.fitlyfe_backend.auth.domain.model.AuthProvider
import com.fitlyfe.fitlyfe_backend.auth.domain.model.User
import com.fitlyfe.fitlyfe_backend.auth.domain.model.UserType
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "users")
data class UserEntity(
    @Id @GeneratedValue(strategy = GenerationType.AUTO)
    val userId: UUID? = null,
    @Column(unique = true, nullable = false)
    val email: String,
    val password: String?,
    val firstName: String,
    val lastName: String,
    val provider: String,
    val userType: String,
    val createdAt: Instant = Instant.now()
) {
    fun toDomain(): User = User(
        userId = userId,
        email = email,
        firstName = firstName,
        lastName = lastName,
        hashedPassword = password,
        authProvider = AuthProvider.valueOf(provider),
        userType =UserType.valueOf(userType),
        createdAt = createdAt
    )

    companion object {
        fun fromDomain(user: User): UserEntity = UserEntity(
            userId = user.userId,
            email = user.email,
            password = user.hashedPassword,
            firstName = user.firstName,
            lastName = user.lastName,
            provider = user.authProvider.name,
            userType = user.userType.name,
            createdAt = user.createdAt
        )
    }
}
