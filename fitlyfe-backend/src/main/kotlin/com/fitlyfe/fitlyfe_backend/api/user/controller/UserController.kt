package com.fitlyfe.fitlyfe_backend.api.user.controller

import com.fitlyfe.fitlyfe_backend.api.user.dto.UserDTO
import com.fitlyfe.fitlyfe_backend.api.user.service.UserService
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.security.oauth2.jwt.Jwt
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping(value = ["/api/users"])
class UserController(
    private val userService: UserService
) {
    @GetMapping(value = ["/me"])
    fun currentUser(@AuthenticationPrincipal jwt: Jwt): UserDTO {
        val userId = jwt.subject
        val email = jwt.getClaim<String>("email")
        val user = userService.getOrCreate(userId, email)
        return UserDTO.fromEntity(user)
    }

}