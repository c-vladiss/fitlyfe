package com.fitlyfe.fitlyfe_backend.api.catalog.repository

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType

interface FoodEntrySearchRepository {

    fun searchByName(
        query: String,
        types: List<FoodEntryType>?,
        limit: Int,
        offset: Int
    ): List<FoodEntryEntity>

    fun countSearchResults(
        query: String,
        types: List<FoodEntryType>?
    ): Long
}
