package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fasterxml.jackson.annotation.JsonIgnoreProperties

/**
 * DTOs mapping the USDA FoodData Central v1 search API response.
 * Only the fields we need are mapped; everything else is ignored.
 *
 * API: GET https://api.nal.usda.gov/fdc/v1/foods/search
 */

@JsonIgnoreProperties(ignoreUnknown = true)
data class UsdaSearchResponse(
    val foods: List<UsdaFood>? = null,
    val totalHits: Int? = null
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class UsdaFood(
    val fdcId: Int? = null,
    val description: String? = null,
    val foodCategory: String? = null,
    val foodNutrients: List<UsdaNutrient>? = null
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class UsdaNutrient(
    val nutrientId: Int? = null,
    val value: Double? = null
)
