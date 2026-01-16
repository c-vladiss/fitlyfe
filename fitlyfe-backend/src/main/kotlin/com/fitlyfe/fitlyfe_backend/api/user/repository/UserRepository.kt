package com.fitlyfe.fitlyfe_backend.api.user.repository

import org.springframework.data.jpa.repository.JpaRepository
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import java.util.UUID

interface UserRepository : JpaRepository<UserEntity, UUID> {
    fun findByKeycloakId(keycloakId: UUID): UserEntity?
    fun findByEmail(email: String): UserEntity?
}