package com.fitlyfe.fitlyfe_backend.api.catalog.seeder

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import com.fasterxml.jackson.annotation.JsonProperty
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.Micronutrients

/**
 * Lightweight DTO for deserializing seed JSON files.
 * Decouples the seed format from the JPA entity structure.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
data class FoodEntrySeedDto(
    val name: String,
    val foodGroup: String? = null,
    val externalId: String? = null,
    val caloriesPer100g: Double? = null,
    val proteinPer100g: Double? = null,
    val carbsPer100g: Double? = null,
    val fatPer100g: Double? = null,
    val fiberPer100g: Double? = null,
    val sugarPer100g: Double? = null,
    val saturatedFatPer100g: Double? = null,
    val micronutrients: MicronutrientsSeedDto? = null
) {
    fun toEntity(): FoodEntryEntity = FoodEntryEntity(
        name = name,
        entryType = FoodEntryType.FOOD,
        entrySource = FoodEntrySource.SEED,
        externalId = externalId,
        caloriesPer100g = caloriesPer100g,
        proteinPer100g = proteinPer100g,
        carbsPer100g = carbsPer100g,
        fatPer100g = fatPer100g,
        fiberPer100g = fiberPer100g,
        sugarPer100g = sugarPer100g,
        saturatedFatPer100g = saturatedFatPer100g,
        micronutrients = micronutrients?.toEntity(),
        verified = true
    )
}

/**
 * Mirrors the seed JSON's micronutrients object.
 * Uses snake_case to match the JSON keys produced by the extraction script.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
data class MicronutrientsSeedDto(
    @JsonProperty("sodium_mg")      val sodiumMg: Double? = null,
    @JsonProperty("potassium_mg")   val potassiumMg: Double? = null,
    @JsonProperty("calcium_mg")     val calciumMg: Double? = null,
    @JsonProperty("iron_mg")        val ironMg: Double? = null,
    @JsonProperty("magnesium_mg")   val magnesiumMg: Double? = null,
    @JsonProperty("zinc_mg")        val zincMg: Double? = null,
    @JsonProperty("phosphorus_mg")  val phosphorusMg: Double? = null,
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
    @JsonProperty("cholesterol_mg") val cholesterolMg: Double? = null
) {
    fun toEntity(): Micronutrients = Micronutrients(
        sodiumMg = sodiumMg,
        potassiumMg = potassiumMg,
        calciumMg = calciumMg,
        ironMg = ironMg,
        magnesiumMg = magnesiumMg,
        zincMg = zincMg,
        phosphorusMg = phosphorusMg,
        vitaminAMcg = vitaminAMcg,
        vitaminCMg = vitaminCMg,
        vitaminDMcg = vitaminDMcg,
        vitaminEMg = vitaminEMg,
        vitaminKMcg = vitaminKMcg,
        vitaminB6Mg = vitaminB6Mg,
        vitaminB12Mcg = vitaminB12Mcg,
        folateMcg = folateMcg,
        niacinMg = niacinMg,
        thiaminMg = thiaminMg,
        riboflavinMg = riboflavinMg,
        cholesterolMg = cholesterolMg
    )
}
