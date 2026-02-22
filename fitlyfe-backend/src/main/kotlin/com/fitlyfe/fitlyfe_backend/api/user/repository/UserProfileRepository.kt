package com.fitlyfe.fitlyfe_backend.api.user.repository

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserProfileEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface UserProfileRepository : JpaRepository<UserProfileEntity, UUID> {
    fun findByUserId(userId: UUID): UserProfileEntity?
}
