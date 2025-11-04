package com.fitlyfe.fitlyfe_backend.auth.domain.model

enum class UserType(val privileges: Set<Privilege>) {
    BASIC(setOf(Privilege.BASIC)),
    PREMIUM(setOf(Privilege.PREMIUM, Privilege.BASIC)),
    ADMIN(setOf(Privilege.ADMIN, Privilege.PREMIUM, Privilege.BASIC))
}