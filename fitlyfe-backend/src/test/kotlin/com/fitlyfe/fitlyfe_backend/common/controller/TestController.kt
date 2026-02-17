package com.fitlyfe.fitlyfe_backend.common.controller

import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.security.Principal

@RestController
@RequestMapping("/test")
class TestController {

    @GetMapping("/admin")
    @PreAuthorize("hasRole('ADMIN')")
    fun adminOnly(principal: Principal): ResponseEntity<String> {
        return ResponseEntity.ok("Hello Admin: ${principal.name}")
    }

    @GetMapping("/user")
    @PreAuthorize("hasRole('USER')")
    fun userOnly(principal: Principal): ResponseEntity<String> {
        return ResponseEntity.ok("Hello User: ${principal.name}")
    }
}
