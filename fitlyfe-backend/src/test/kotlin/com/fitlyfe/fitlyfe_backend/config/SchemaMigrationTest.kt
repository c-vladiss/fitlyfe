package com.fitlyfe.fitlyfe_backend.config

import com.fitlyfe.fitlyfe_backend.common.AbstractIntegrationTest
import org.flywaydb.core.Flyway
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.core.env.Environment

/**
 * The test context builds the schema with Flyway alone and then starts Hibernate
 * with ddl-auto=validate, so simply loading the context proves the migrations
 * produce exactly the schema the entities expect.
 */
class SchemaMigrationTest : AbstractIntegrationTest() {

    @Autowired
    lateinit var flyway: Flyway

    @Autowired
    lateinit var environment: Environment

    @Test
    fun `all migrations apply cleanly to an empty database`() {
        val info = flyway.info()
        assertTrue(info.pending().isEmpty(), "Pending migrations: ${info.pending().map { it.version }}")
        assertTrue(info.applied().all { it.state.isApplied && !it.state.isFailed })
        assertEquals("8", info.current().version.version)
    }

    @Test
    fun `hibernate validates the schema instead of changing it`() {
        assertEquals("validate", environment.getProperty("spring.jpa.hibernate.ddl-auto"))
    }
}
