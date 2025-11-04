package com.fitlyfe.fitlyfe_backend.common.config

import io.github.cdimascio.dotenv.Dotenv
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class EnvConfig {
    @Value("\${JWT_SECRET}")
    private lateinit var jwtSecret: String

    @Value("\${JWT_EXPIRATION_MS}")
    private var jwtExpirationMs: Long = 0

    @Bean
    fun jwtSecret(): String = jwtSecret

    @Bean
    fun jwtExpirationMs(): Long = jwtExpirationMs
}