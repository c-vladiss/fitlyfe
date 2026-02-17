package com.fitlyfe.fitlyfe_backend.api.auth.controller

import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import org.springframework.graphql.data.method.annotation.MutationMapping
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.stereotype.Controller
import java.util.UUID

@Controller
class AuthGraphQLController(
    private val userService: UserService
) {
    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun syncUser(@AuthenticationPrincipal jwt: Jwt): SyncUserResult {
        val supabaseId = UUID.fromString(jwt.subject)
        val email = jwt.getClaim<String>("email")
            ?: throw IllegalStateException("email claim missing from JWT")

        // Supabase Google OAuth does not promote given_name/family_name to the
        // top-level JWT; it puts them inside user_metadata.  Try top-level OIDC
        // claims first, then fall back to user_metadata.full_name (split on the
        // first space), then to user_metadata.name.
        val firstName: String?
        val lastName: String?

        val directFirst = jwt.getClaim<String>("given_name")
        val directLast  = jwt.getClaim<String>("family_name")

        if (directFirst != null || directLast != null) {
            firstName = directFirst
            lastName  = directLast
        } else {
            @Suppress("UNCHECKED_CAST")
            val meta = jwt.getClaim<Map<String, Any>>("user_metadata")
            val fullName = (meta?.get("full_name") as? String)
                ?: (meta?.get("name") as? String)
                ?: jwt.getClaim<String>("name")

            if (fullName != null) {
                val spaceIdx = fullName.indexOf(' ')
                firstName = if (spaceIdx > 0) fullName.substring(0, spaceIdx) else fullName
                lastName  = if (spaceIdx > 0) fullName.substring(spaceIdx + 1).trim().ifEmpty { null } else null
            } else {
                firstName = null
                lastName  = null
            }
        }

        val (user, requiresOnboarding) = userService.syncUser(supabaseId, email, firstName, lastName)

        return SyncUserResult(
            id = user.id.toString(),
            email = user.email,
            firstName = user.firstName,
            lastName = user.lastName,
            requiresOnboarding = requiresOnboarding
        )
    }

    @MutationMapping
    @PreAuthorize("isAuthenticated()")
    fun completeOnboarding(@AuthenticationPrincipal jwt: Jwt): Boolean {
        val supabaseId = UUID.fromString(jwt.subject)
        userService.markOnboardingComplete(supabaseId)
        return true
    }
}

data class SyncUserResult(
    val id: String,
    val email: String,
    val firstName: String?,
    val lastName: String?,
    val requiresOnboarding: Boolean
)
