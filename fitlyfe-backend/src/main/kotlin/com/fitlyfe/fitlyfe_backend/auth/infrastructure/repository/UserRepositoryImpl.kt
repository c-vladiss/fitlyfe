package com.fitlyfe.fitlyfe_backend.auth.infrastructure.repository

import com.fitlyfe.fitlyfe_backend.auth.domain.model.User
import com.fitlyfe.fitlyfe_backend.auth.infrastructure.entity.UserEntity
import org.springframework.stereotype.Repository

@Repository
class UserRepositoryImpl(
    private val repository: JpaUserRepository
): UserRepository {
    override fun findUserByEmail(email: String): User? = repository.findByEmail(email)?.toDomain()
    override fun saveUser(user: User): User = repository.save(UserEntity.fromDomain(user)).toDomain()
}