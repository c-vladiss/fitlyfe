package com.fitlyfe.fitlyfe_backend.api.common.exception

import graphql.GraphQLError
import graphql.GraphqlErrorBuilder
import graphql.schema.DataFetchingEnvironment
import org.slf4j.LoggerFactory
import org.springframework.graphql.execution.DataFetcherExceptionResolverAdapter
import org.springframework.graphql.execution.ErrorType
import org.springframework.stereotype.Component

@Component
class GraphQLExceptionHandler : DataFetcherExceptionResolverAdapter() {
    private val log = LoggerFactory.getLogger(GraphQLExceptionHandler::class.java)

    override fun resolveToSingleError(ex: Throwable, env: DataFetchingEnvironment): GraphQLError? {
        log.error("GraphQL Error: ${ex.message}")

        val errorType = if (ex is org.springframework.security.access.AccessDeniedException) {
            ErrorType.FORBIDDEN
        } else {
            ErrorType.INTERNAL_ERROR
        }

        return GraphqlErrorBuilder.newError()
            .errorType(errorType)
            .message(ex.message ?: "Internal Server Error")
            .path(env.executionStepInfo.path)
            .location(env.field.sourceLocation)
            .build()
    }
}
