package com.fitlyfe.fitlyfe_backend.api.nutrition.repository

import com.fitlyfe.fitlyfe_backend.api.nutrition.entity.FoodEntity
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface FoodRepository : JpaRepository<FoodEntity, UUID>
