package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.UserMealTypeEntity
import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface UserMealTypeRepository : JpaRepository<UserMealTypeEntity, UUID> {
    fun findByUserOrderBySortOrderAsc(user: UserEntity): List<UserMealTypeEntity>
    fun findByUserAndName(user: UserEntity, name: String): UserMealTypeEntity?
    fun deleteAllByUser(user: UserEntity)
}
