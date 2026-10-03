package com.fitlyfe.fitlyfe_backend.api.catalog.dto

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity

data class FoodSearchResult(
    val items: List<FoodEntryEntity>,
    val total: Long,
    val hasMore: Boolean
)
