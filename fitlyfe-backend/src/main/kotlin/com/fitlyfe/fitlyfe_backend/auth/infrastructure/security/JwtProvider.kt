package com.fitlyfe.fitlyfe_backend.auth.infrastructure.security

import io.jsonwebtoken.Jwts
import io.jsonwebtoken.SignatureAlgorithm
import io.jsonwebtoken.security.Keys
import org.springframework.stereotype.Component
import java.security.Key
import java.util.Date

@Component
class JwtProvider(
    jwtSecret: String,
    private val jwtExpirationMs: Long
) {
    private val secret: Key  = Keys.hmacShaKeyFor( jwtSecret.toByteArray())

    fun generateToken(email: String): String{
        val now = Date()
        val expiryDate = Date(now.time + jwtExpirationMs)
        return Jwts.builder()
            .setSubject(email)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(secret,SignatureAlgorithm.HS512)
            .compact()
    }

    fun getEmailFromToken(token: String): String =
        Jwts.parserBuilder().setSigningKey(secret).build().parseClaimsJws(token).body.subject
}