package com.fitlyfe.fitlyfe_backend.config

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test
import org.springframework.boot.env.YamlPropertySourceLoader
import org.springframework.core.env.StandardEnvironment
import org.springframework.core.io.FileSystemResource

/**
 * Guards the production defaults in src/main/resources/application.yaml.
 * (Integration tests use src/test/resources/application.yaml, which shadows it.)
 */
class ApplicationConfigTest {

    private fun loadMainConfig(): StandardEnvironment {
        val env = StandardEnvironment()
        // Drop OS env vars / system properties so a developer's .env can't mask the defaults
        env.propertySources.remove(StandardEnvironment.SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME)
        env.propertySources.remove(StandardEnvironment.SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME)
        YamlPropertySourceLoader()
            .load("main", FileSystemResource("src/main/resources/application.yaml"))
            .forEach { env.propertySources.addLast(it) }
        return env
    }

    @Test
    fun `flyway owns the schema and hibernate only validates it`() {
        val env = loadMainConfig()
        assertEquals("validate", env.getProperty("spring.jpa.hibernate.ddl-auto"))
        assertEquals("true", env.getProperty("spring.flyway.enabled"))
        assertNull(env.getProperty("spring.flyway.baseline-on-migrate"))
    }

    @Test
    fun `sql logging and graphiql are off by default`() {
        val env = loadMainConfig()
        assertEquals("false", env.getProperty("spring.jpa.show-sql"))
        assertEquals("false", env.getProperty("spring.jpa.properties.hibernate.format_sql"))
        assertEquals("false", env.getProperty("spring.graphql.graphiql.enabled"))
    }
}
