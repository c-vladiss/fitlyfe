package com.fitlyfe.fitlyfe_backend.api.common.exception

import graphql.GraphQLError
import graphql.GraphqlErrorBuilder
import graphql.schema.DataFetchingEnvironment
import jakarta.persistence.EntityNotFoundException
import org.slf4j.LoggerFactory
import org.springframework.graphql.execution.DataFetcherExceptionResolverAdapter
import org.springframework.graphql.execution.ErrorType
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.core.AuthenticationException
import org.springframework.stereotype.Component
import java.time.format.DateTimeParseException

@Component
class GraphQLExceptionHandler : DataFetcherExceptionResolverAdapter() {
    private val log = LoggerFactory.getLogger(GraphQLExceptionHandler::class.java)

    override fun resolveToSingleError(ex: Throwable, env: DataFetchingEnvironment): GraphQLError? {
        val (errorType, message) = when (ex) {
            is AccessDeniedException -> ErrorType.FORBIDDEN to "Access denied"
            is AuthenticationException -> ErrorType.UNAUTHORIZED to "Unauthorized"
            is EntityNotFoundException, is NoSuchElementException ->
                ErrorType.NOT_FOUND to (ex.message ?: "Not found")
            // Invalid client input (bad IDs, malformed dates, ownership checks)
            is IllegalArgumentException, is DateTimeParseException ->
                ErrorType.BAD_REQUEST to (ex.message ?: "Bad request")
            // Anything else is a server bug: log it in full, but don't leak internals
            // such as SQL or class names to the client.
            else -> {
                log.error("Unhandled GraphQL error at ${env.executionStepInfo.path}", ex)
                ErrorType.INTERNAL_ERROR to "Internal server error"
            }
        }
        if (errorType != ErrorType.INTERNAL_ERROR) {
            log.debug("GraphQL {} at {}: {}", errorType, env.executionStepInfo.path, ex.message)
        }

        return GraphqlErrorBuilder.newError()
            .errorType(errorType)
            .message(message)
            .path(env.executionStepInfo.path)
            .location(env.field.sourceLocation)
            .build()
    }
}
