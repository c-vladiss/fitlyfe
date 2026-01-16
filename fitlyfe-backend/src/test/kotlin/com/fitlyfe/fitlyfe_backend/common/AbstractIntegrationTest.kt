package com.fitlyfe.fitlyfe_backend.common

import dasniko.testcontainers.keycloak.KeycloakContainer
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
abstract class AbstractIntegrationTest {

    companion object {
        @Container
        val postgres = PostgreSQLContainer("postgres:16-alpine").apply {
            withDatabaseName("fitlyfe")
            withUsername("test")
            withPassword("test")
        }

        @Container
        val keycloak = KeycloakContainer("quay.io/keycloak/keycloak:26.0.0").apply {
            withRealmImportFile("realm-test.json")
            withAdminUsername("admin")
            withAdminPassword("admin")
        }

        @JvmStatic
        @org.junit.jupiter.api.BeforeAll
        fun setupKeycloak() {
            if (!keycloak.isRunning) {
                keycloak.start()
            }

            // Configure kcadm
            var result = keycloak.execInContainer("/opt/keycloak/bin/kcadm.sh", "config", "credentials", "--server", "http://localhost:8080", "--realm", "master", "--user", "admin", "--password", "admin")
            if (result.exitCode != 0) {
                throw RuntimeException("Failed to config kcadm credentials: ${result.stderr}")
            }
            
            // Assign manage-users role to service account
            // Service account username is service-account-<client-id>
            result = keycloak.execInContainer("/opt/keycloak/bin/kcadm.sh", "add-roles", "-r", "fitlyfe", "--uusername", "service-account-fitlyfe-backend", "--cclientid", "realm-management", "--rolename", "manage-users")
             if (result.exitCode != 0) {
                throw RuntimeException("Failed to add roles: ${result.stderr}")
            }
        }

        @JvmStatic
        @DynamicPropertySource
        fun properties(registry: DynamicPropertyRegistry) {
            // Postgres
            registry.add("spring.datasource.url", postgres::getJdbcUrl)
            registry.add("spring.datasource.username", postgres::getUsername)
            registry.add("spring.datasource.password", postgres::getPassword)
            
            // Keycloak
            registry.add("keycloak.server-url", keycloak::getAuthServerUrl)
            registry.add("keycloak.realm") { "fitlyfe" }
            registry.add("keycloak.admin-client-id") { "fitlyfe-backend" }
            registry.add("keycloak.client-secret") { "test-secret" }
            registry.add("keycloak.mobile-callback-uri") { "http://localhost:8080/callback" } // Dummy
            
            // Spring Security Resource Server
            registry.add("spring.security.oauth2.resourceserver.jwt.issuer-uri") { 
                "${keycloak.authServerUrl}/realms/fitlyfe"
            }
        }
    }
}
