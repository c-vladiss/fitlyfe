package com.fitlyfe.fitlyfe_backend.auth.infrastructure.security

import org.springframework.beans.factory.annotation.Value
import org.springframework.core.convert.converter.Converter
import org.springframework.security.authentication.AbstractAuthenticationToken
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken
import org.springframework.security.oauth2.server.resource.authentication.JwtGrantedAuthoritiesConverter
import org.springframework.stereotype.Component

@Component
class JwtAuthConverter(
    @Value("\${keycloak.client-id:fitlyfe-backend}") // Default to fitlyfe-backend if not set
    private val propertiesClientId: String
) : Converter<Jwt, AbstractAuthenticationToken> {

    private val jwtGrantedAuthoritiesConverter = JwtGrantedAuthoritiesConverter()

    override fun convert(jwt: Jwt): AbstractAuthenticationToken {
        val authorities = mutableSetOf<GrantedAuthority>()
        authorities.addAll(jwtGrantedAuthoritiesConverter.convert(jwt) ?: emptySet())
        authorities.addAll(extractResourceRoles(jwt))

        return JwtAuthenticationToken(jwt, authorities, getPrincipalClaimName(jwt))
    }

    private fun getPrincipalClaimName(jwt: Jwt): String {
        val claimNames = jwt.claims.keys
        return claimNames.firstOrNull { it == "preferred_username" }
            ?.let { jwt.getClaimAsString(it) }
            ?: jwt.subject
    }

    private fun extractResourceRoles(jwt: Jwt): Collection<GrantedAuthority> {
        val resourceAccess = jwt.getClaim<Map<String, Any>>("resource_access") ?: return emptySet()
        val resource = resourceAccess[propertiesClientId] as? Map<*, *> ?: return emptySet()
        val resourceRoles = resource["roles"] as? Collection<*> ?: return emptySet()

        return resourceRoles.filterIsInstance<String>()
            .map { SimpleGrantedAuthority("ROLE_${it.uppercase().replace("-", "_")}") }
            .toSet()
    }
}
