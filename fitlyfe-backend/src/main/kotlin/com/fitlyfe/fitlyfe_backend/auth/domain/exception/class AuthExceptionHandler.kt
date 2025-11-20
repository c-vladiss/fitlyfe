package com.fitlyfe.fitlyfe_backend.auth.domain.exception

import com.fitlyfe.fitlyfe_backend.auth.application.dto.ApiAuthError
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice


class UserAlreadyExistsException(message: String) : RuntimeException(message)
class InvalidCredentialsException(message: String) : RuntimeException(message)
class KeycloakServiceException(message: String) : RuntimeException(message)

@RestControllerAdvice
class AuthExceptionHandler {
    @ExceptionHandler(UserAlreadyExistsException::class)
    fun handleUserExists(ex: UserAlreadyExistsException): ResponseEntity<ApiAuthError> =
        ResponseEntity
            .status(409)
            .body(ApiAuthError("USER_ALREADY_EXISTS", ex.message ?: "User already exists"))

    @ExceptionHandler(InvalidCredentialsException::class)
    fun handleInvalidCredentials(ex: InvalidCredentialsException): ResponseEntity<ApiAuthError> =
        ResponseEntity
            .status(401)
            .body(ApiAuthError("INVALID_CREDENTIALS", ex.message ?: "Username or password is incorrect"))

    @ExceptionHandler(KeycloakServiceException::class)
    fun handleKeycloakError(ex: KeycloakServiceException): ResponseEntity<ApiAuthError> =
        ResponseEntity
            .status(502)
            .body(ApiAuthError("KEYCLOAK_ERROR", ex.message ?: "Error contacting Keycloak"))

    @ExceptionHandler(Exception::class)
    fun handleGeneric(ex: Exception): ResponseEntity<ApiAuthError> =
        ResponseEntity
            .status(500)
            .body(ApiAuthError("INTERNAL_ERROR", ex.message ?: "An unexpected error occurred"))
}