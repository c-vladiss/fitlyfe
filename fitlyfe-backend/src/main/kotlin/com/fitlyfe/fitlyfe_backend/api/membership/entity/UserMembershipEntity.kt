package com.fitlyfe.fitlyfe_backend.api.membership.entity

import com.fitlyfe.fitlyfe_backend.api.user.entity.UserEntity
import jakarta.persistence.*
import java.time.LocalDateTime
import java.util.UUID

@Entity
@Table(name = "user_memberships")
data class UserMembershipEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    val user: UserEntity,

    val provider: String? = null,
    
    @Column(name = "product_id")
    val productId: String? = null,

    @Column(name = "transaction_id")
    val transactionId: String? = null,

    @Column(name = "original_transaction_id")
    val originalTransactionId: String? = null,

    @Column(name = "starts_at")
    val startsAt: LocalDateTime? = null,

    @Column(name = "expires_at")
    val expiresAt: LocalDateTime? = null,

    @Column(name = "auto_renew")
    val autoRenew: Boolean? = null,

    val status: String? = null,

    @Column(name = "created_at")
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at")
    val updatedAt: LocalDateTime = LocalDateTime.now()
)
