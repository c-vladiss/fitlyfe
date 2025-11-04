package com.fitlyfe.fitlyfe_backend.auth.infrastructure.repository

import com.fitlyfe.fitlyfe_backend.auth.infrastructure.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface  JpaUserRepository : JpaRepository<UserEntity, UUID>{
    fun findByEmail(email: String): UserEntity?
}
