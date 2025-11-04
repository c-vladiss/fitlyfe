package com.fitlyfe.fitlyfe_backend.auth.domain.repository

import com.fitlyfe.fitlyfe_backend.auth.domain.model.User

interface UserRepository {
    fun findUserByEmail(email: String): User?
    fun saveUser(user: User): User
}