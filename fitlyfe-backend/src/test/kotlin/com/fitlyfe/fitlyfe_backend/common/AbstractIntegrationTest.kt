package com.fitlyfe.fitlyfe_backend.common

import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.PostgreSQLContainer

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Import(TestSecurityConfig::class)
abstract class AbstractIntegrationTest {

    companion object {
        // One container for the whole test run. Spring caches the application
        // context across test classes, so a per-class container would leave
        // later classes pointing at a stopped database.
        val postgres = PostgreSQLContainer("postgres:16-alpine").apply {
            withDatabaseName("fitlyfe")
            withUsername("test")
            withPassword("test")
            start()
        }

        @JvmStatic
        @DynamicPropertySource
        fun properties(registry: DynamicPropertyRegistry) {
            // Postgres
            registry.add("spring.datasource.url", postgres::getJdbcUrl)
            registry.add("spring.datasource.username", postgres::getUsername)
            registry.add("spring.datasource.password", postgres::getPassword)
        }
    }
}
