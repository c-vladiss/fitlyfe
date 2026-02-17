package com.fitlyfe.fitlyfe_backend

import io.github.cdimascio.dotenv.Dotenv
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class FitlyfeBackendApplication

fun main(args: Array<String>) {
    Dotenv.configure()
        .ignoreIfMissing()
        .systemProperties()
        .load()
	runApplication<FitlyfeBackendApplication>(*args)
}
