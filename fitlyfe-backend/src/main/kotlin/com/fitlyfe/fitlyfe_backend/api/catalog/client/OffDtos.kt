package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty

/**
 * DTOs mapping the Open Food Facts v2 API product response.
 * Only the fields we need are mapped; everything else is ignored.
 */

@JsonIgnoreProperties(ignoreUnknown = true)
data class OffResponse(
    val status: Int? = null,
    val product: OffProduct? = null
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class OffProduct(
    @JsonProperty("product_name")
    val productName: String? = null,

    val brands: String? = null,

    @JsonProperty("serving_size")
    val servingSize: String? = null,

    val nutriments: OffNutriments? = null
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class OffNutriments(
    // Macros (per 100g)
    @JsonProperty("energy-kcal_100g")
    val energyKcal100g: Double? = null,

    @JsonProperty("proteins_100g")
    val proteins100g: Double? = null,

    @JsonProperty("carbohydrates_100g")
    val carbohydrates100g: Double? = null,

    @JsonProperty("fat_100g")
    val fat100g: Double? = null,

    @JsonProperty("fiber_100g")
    val fiber100g: Double? = null,

    @JsonProperty("sugars_100g")
    val sugars100g: Double? = null,

    @JsonProperty("saturated-fat_100g")
    val saturatedFat100g: Double? = null,

    // Minerals (per 100g, in grams — we convert to mg/mcg in the client)
    @JsonProperty("sodium_100g")
    val sodium100g: Double? = null,

    @JsonProperty("potassium_100g")
    val potassium100g: Double? = null,

    @JsonProperty("calcium_100g")
    val calcium100g: Double? = null,

    @JsonProperty("iron_100g")
    val iron100g: Double? = null,

    @JsonProperty("magnesium_100g")
    val magnesium100g: Double? = null,

    @JsonProperty("zinc_100g")
    val zinc100g: Double? = null,

    @JsonProperty("phosphorus_100g")
    val phosphorus100g: Double? = null,

    // Vitamins (per 100g, in grams — we convert to mg/mcg in the client)
    @JsonProperty("vitamin-a_100g")
    val vitaminA100g: Double? = null,

    @JsonProperty("vitamin-c_100g")
    val vitaminC100g: Double? = null,

    @JsonProperty("vitamin-d_100g")
    val vitaminD100g: Double? = null,

    @JsonProperty("vitamin-e_100g")
    val vitaminE100g: Double? = null,

    @JsonProperty("vitamin-b12_100g")
    val vitaminB12100g: Double? = null,

    @JsonProperty("cholesterol_100g")
    val cholesterol100g: Double? = null
)
