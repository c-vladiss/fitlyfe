package com.fitlyfe.fitlyfe_backend.api.catalog.repository

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface FoodEntryRepository : JpaRepository<FoodEntryEntity, UUID>, FoodEntrySearchRepository {

    fun findByBarcode(barcode: String): FoodEntryEntity?

    fun findByExternalIdAndEntrySource(externalId: String, entrySource: FoodEntrySource): FoodEntryEntity?

    fun countByEntrySource(entrySource: FoodEntrySource): Long

    fun countByEntrySourceIn(sources: List<FoodEntrySource>): Long
}
