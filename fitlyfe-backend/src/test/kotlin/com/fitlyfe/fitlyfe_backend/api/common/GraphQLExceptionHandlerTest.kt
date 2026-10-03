package com.fitlyfe.fitlyfe_backend.api.common

import com.fitlyfe.fitlyfe_backend.api.common.exception.GraphQLExceptionHandler
import graphql.execution.ExecutionStepInfo
import graphql.execution.ResultPath
import graphql.language.Field
import graphql.schema.DataFetchingEnvironment
import jakarta.persistence.EntityNotFoundException
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.mockito.kotlin.doReturn
import org.mockito.kotlin.mock
import org.springframework.graphql.execution.ErrorType
import org.springframework.security.access.AccessDeniedException
import java.time.LocalDate
import java.time.format.DateTimeParseException

class GraphQLExceptionHandlerTest {

    private val handler = object : GraphQLExceptionHandler() {
        fun resolve(ex: Throwable) = resolveToSingleError(ex, env)!!
    }

    private val stepInfo = mock<ExecutionStepInfo> { on { path } doReturn ResultPath.rootPath() }
    private val env = mock<DataFetchingEnvironment> {
        on { executionStepInfo } doReturn stepInfo
        on { field } doReturn Field("someField")
    }

    @Test
    fun `unexpected exceptions do not leak their message`() {
        val error = handler.resolve(RuntimeException("ERROR: relation \"users\" does not exist"))
        assertEquals(ErrorType.INTERNAL_ERROR, error.errorType)
        assertEquals("Internal server error", error.message)
    }

    @Test
    fun `client errors keep their message`() {
        val notFound = handler.resolve(EntityNotFoundException("Meal not found: 123"))
        assertEquals(ErrorType.NOT_FOUND, notFound.errorType)
        assertEquals("Meal not found: 123", notFound.message)

        val badInput = handler.resolve(IllegalArgumentException("Meal does not belong to user"))
        assertEquals(ErrorType.BAD_REQUEST, badInput.errorType)
        assertEquals("Meal does not belong to user", badInput.message)

        val badDate = handler.resolve(runCatching { LocalDate.parse("nope") }.exceptionOrNull() as DateTimeParseException)
        assertEquals(ErrorType.BAD_REQUEST, badDate.errorType)
    }

    @Test
    fun `access denied maps to FORBIDDEN`() {
        val error = handler.resolve(AccessDeniedException("Access Denied"))
        assertEquals(ErrorType.FORBIDDEN, error.errorType)
    }
}
