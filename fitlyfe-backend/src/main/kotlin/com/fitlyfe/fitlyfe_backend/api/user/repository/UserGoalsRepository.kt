package com.fitlyfe.fitlyfe_backend.api.user.repository

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserGoalsEntity
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface UserGoalsRepository : JpaRepository<UserGoalsEntity, UUID> {
    fun findByUserId(userId: UUID): UserGoalsEntity?
}
