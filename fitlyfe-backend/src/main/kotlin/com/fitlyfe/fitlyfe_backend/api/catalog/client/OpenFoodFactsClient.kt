package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.Micronutrients
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient
import org.springframework.web.client.RestClientException

@Component
class OpenFoodFactsClient(
    restClientBuilder: RestClient.Builder
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    private val restClient = restClientBuilder
        .baseUrl("https://world.openfoodfacts.org")
        .defaultHeader("User-Agent", "FitLyfe/1.0 (fitness-tracking-app)")
        .build()

    /**
     * Looks up a product by barcode via the Open Food Facts API.
     * Returns a [FoodEntryEntity] ready to be persisted, or null if not found.
     */
    fun fetchByBarcode(barcode: String): FoodEntryEntity? {
        return try {
            val response = restClient.get()
                .uri("/api/v2/product/{barcode}?fields=product_name,brands,serving_size,nutriments", barcode)
                .retrieve()
                .body(OffResponse::class.java)

            if (response?.status != 1 || response.product == null) {
                logger.debug("Open Food Facts: product not found for barcode {}", barcode)
                return null
            }

            mapToFoodEntry(response.product, barcode)
        } catch (e: RestClientException) {
            logger.warn("Open Food Facts API call failed for barcode {}: {}", barcode, e.message)
            null
        }
    }

    private fun mapToFoodEntry(product: OffProduct, barcode: String): FoodEntryEntity {
        val n = product.nutriments

        return FoodEntryEntity(
            name = product.productName?.trim()?.ifBlank { null } ?: "Unknown Product",
            brand = product.brands?.trim()?.ifBlank { null },
            entryType = FoodEntryType.PRODUCT,
            barcode = barcode,
            servingSizeG = parseServingSizeG(product.servingSize),
            caloriesPer100g = n?.energyKcal100g,
            proteinPer100g = n?.proteins100g,
            carbsPer100g = n?.carbohydrates100g,
            fatPer100g = n?.fat100g,
            fiberPer100g = n?.fiber100g,
            sugarPer100g = n?.sugars100g,
            saturatedFatPer100g = n?.saturatedFat100g,
            micronutrients = mapMicronutrients(n),
            entrySource = FoodEntrySource.OPEN_FOOD_FACTS,
            externalId = barcode,
            verified = false
        )
    }

    private fun mapMicronutrients(n: OffNutriments?): Micronutrients? {
        if (n == null) return null

        val micros = Micronutrients(
            // OFF stores sodium in grams — convert to mg
            sodiumMg = n.sodium100g?.times(1000),
            potassiumMg = n.potassium100g?.times(1000),
            calciumMg = n.calcium100g?.times(1000),
            ironMg = n.iron100g?.times(1000),
            magnesiumMg = n.magnesium100g?.times(1000),
            zincMg = n.zinc100g?.times(1000),
            phosphorusMg = n.phosphorus100g?.times(1000),
            vitaminAMcg = n.vitaminA100g?.times(1_000_000),
            vitaminCMg = n.vitaminC100g?.times(1000),
            vitaminDMcg = n.vitaminD100g?.times(1_000_000),
            vitaminEMg = n.vitaminE100g?.times(1000),
            vitaminB12Mcg = n.vitaminB12100g?.times(1_000_000),
            cholesterolMg = n.cholesterol100g?.times(1000)
        )

        // Return null if every field is null (no useful micronutrient data)
        return if (micros == Micronutrients()) null else micros
    }

    /**
     * Parses serving size strings like "30g", "100 ml", "1 slice (25g)" into grams.
     * Returns null if not parsable.
     */
    private fun parseServingSizeG(raw: String?): Double? {
        if (raw.isNullOrBlank()) return null
        val match = Regex("""(\d+(?:\.\d+)?)\s*g""", RegexOption.IGNORE_CASE).find(raw)
        return match?.groupValues?.get(1)?.toDoubleOrNull()
    }
}
