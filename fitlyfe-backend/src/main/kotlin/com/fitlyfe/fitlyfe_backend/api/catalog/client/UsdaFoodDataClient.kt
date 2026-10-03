package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.Micronutrients
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException

@Component
class UsdaFoodDataClient(
    restClientBuilder: RestClient.Builder,
    @Value("\${usda.api-key}") private val apiKey: String
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    private val restClient = restClientBuilder
        .baseUrl("https://api.nal.usda.gov/fdc/v1")
        .build()

    // USDA nutrient IDs → values are already in the correct units for our schema
    // (kcal, g, mg, mcg — no conversion needed unlike the OFF CSV)
    private val macroIds = mapOf(
        1008 to "calories",        // Energy, kcal
        1003 to "protein",         // Protein, g
        1004 to "fat",             // Total lipid (fat), g
        1005 to "carbs",           // Carbohydrate by difference, g
        1079 to "fiber",           // Fiber total dietary, g
        2000 to "sugar",           // Total Sugars, g
        1258 to "saturatedFat"     // Fatty acids total saturated, g
    )

    private val microIds = mapOf(
        1093 to "sodium",          // Sodium, mg
        1092 to "potassium",       // Potassium, mg
        1087 to "calcium",         // Calcium, mg
        1089 to "iron",            // Iron, mg
        1090 to "magnesium",       // Magnesium, mg
        1095 to "zinc",            // Zinc, mg
        1091 to "phosphorus",      // Phosphorus, mg
        1106 to "vitaminA",        // Vitamin A RAE, mcg
        1162 to "vitaminC",        // Vitamin C, mg
        1114 to "vitaminD",        // Vitamin D (D2+D3), mcg
        1109 to "vitaminE",        // Vitamin E alpha-tocopherol, mg
        1185 to "vitaminK",        // Vitamin K phylloquinone, mcg
        1175 to "vitaminB6",       // Vitamin B-6, mg
        1178 to "vitaminB12",      // Vitamin B-12, mcg
        1190 to "folate",          // Folate DFE, mcg
        1167 to "niacin",          // Niacin, mg
        1165 to "thiamin",         // Thiamin, mg
        1166 to "riboflavin",      // Riboflavin, mg
        1253 to "cholesterol"      // Cholesterol, mg
    )

    /**
     * Searches the USDA FoodData Central for foods matching [query].
     * Restricts to SR Legacy and Foundation datasets for highest quality generic foods.
     * Returns a list of [FoodEntryEntity] objects ready to be persisted.
     */
    fun search(query: String, pageSize: Int = 25): List<FoodEntryEntity> {
        return try {
            val response = restClient.get()
                .uri { builder ->
                    builder.path("/foods/search")
                        .queryParam("query", query)
                        .queryParam("dataType", "SR Legacy,Foundation")
                        .queryParam("pageSize", pageSize)
                        .queryParam("api_key", apiKey)
                        .build()
                }
                .retrieve()
                .body(UsdaSearchResponse::class.java)

            response?.foods
                ?.mapNotNull { mapToFoodEntry(it) }
                ?: emptyList()
        } catch (e: RestClientException) {
            logger.warn("USDA FoodData Central search failed for query '{}': {}", query, e.message)
            emptyList()
        }
    }

    private fun mapToFoodEntry(food: UsdaFood): FoodEntryEntity? {
        val name = food.description?.trim()?.ifBlank { null } ?: return null

        val nutrients: Map<Int, Double> = food.foodNutrients
            ?.filter { it.nutrientId != null && it.value != null }
            ?.associate { it.nutrientId!! to it.value!! }
            ?: emptyMap()

        val macros = macroIds.entries.associate { (id, key) -> key to nutrients[id] }

        // Require at least energy or protein to be useful
        if (macros["calories"] == null && macros["protein"] == null) return null

        return FoodEntryEntity(
            name = name,
            entryType = FoodEntryType.FOOD,
            entrySource = FoodEntrySource.USDA,
            externalId = food.fdcId?.toString(),
            caloriesPer100g = macros["calories"],
            proteinPer100g = macros["protein"],
            carbsPer100g = macros["carbs"],
            fatPer100g = macros["fat"],
            fiberPer100g = macros["fiber"],
            sugarPer100g = macros["sugar"],
            saturatedFatPer100g = macros["saturatedFat"],
            micronutrients = mapMicronutrients(nutrients),
            verified = true
        )
    }

    private fun mapMicronutrients(nutrients: Map<Int, Double>): Micronutrients? {
        val micros = Micronutrients(
            sodiumMg      = nutrients[1093],
            potassiumMg   = nutrients[1092],
            calciumMg     = nutrients[1087],
            ironMg        = nutrients[1089],
            magnesiumMg   = nutrients[1090],
            zincMg        = nutrients[1095],
            phosphorusMg  = nutrients[1091],
            vitaminAMcg   = nutrients[1106],
            vitaminCMg    = nutrients[1162],
            vitaminDMcg   = nutrients[1114],
            vitaminEMg    = nutrients[1109],
            vitaminKMcg   = nutrients[1185],
            vitaminB6Mg   = nutrients[1175],
            vitaminB12Mcg = nutrients[1178],
            folateMcg     = nutrients[1190],
            niacinMg      = nutrients[1167],
            thiaminMg     = nutrients[1165],
            riboflavinMg  = nutrients[1166],
            cholesterolMg = nutrients[1253]
        )
        return if (micros == Micronutrients()) null else micros
    }
}
