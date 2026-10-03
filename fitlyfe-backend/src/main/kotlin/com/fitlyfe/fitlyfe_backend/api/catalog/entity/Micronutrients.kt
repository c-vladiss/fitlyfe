package com.fitlyfe.fitlyfe_backend.api.catalog.entity

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty

/**
 * Fitness-relevant micronutrients stored as JSONB in food_entries.
 * Covers FDA nutrition label requirements and common supplement targets.
 * All values are per 100 g of the food entry.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
data class Micronutrients(

    // Minerals
    @JsonProperty("sodium_mg")      val sodiumMg: Double? = null,
    @JsonProperty("potassium_mg")   val potassiumMg: Double? = null,
    @JsonProperty("calcium_mg")     val calciumMg: Double? = null,
    @JsonProperty("iron_mg")        val ironMg: Double? = null,
    @JsonProperty("magnesium_mg")   val magnesiumMg: Double? = null,
    @JsonProperty("zinc_mg")        val zincMg: Double? = null,
    @JsonProperty("phosphorus_mg")  val phosphorusMg: Double? = null,

    // Vitamins
    @JsonProperty("vitamin_a_mcg")  val vitaminAMcg: Double? = null,
    @JsonProperty("vitamin_c_mg")   val vitaminCMg: Double? = null,
    @JsonProperty("vitamin_d_mcg")  val vitaminDMcg: Double? = null,
    @JsonProperty("vitamin_e_mg")   val vitaminEMg: Double? = null,
    @JsonProperty("vitamin_k_mcg")  val vitaminKMcg: Double? = null,
    @JsonProperty("vitamin_b6_mg")  val vitaminB6Mg: Double? = null,
    @JsonProperty("vitamin_b12_mcg") val vitaminB12Mcg: Double? = null,
    @JsonProperty("folate_mcg")     val folateMcg: Double? = null,
    @JsonProperty("niacin_mg")      val niacinMg: Double? = null,
    @JsonProperty("thiamin_mg")     val thiaminMg: Double? = null,
    @JsonProperty("riboflavin_mg")  val riboflavinMg: Double? = null,

    // Other
    @JsonProperty("cholesterol_mg") val cholesterolMg: Double? = null
)
