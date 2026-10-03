package com.fitlyfe.fitlyfe_backend.api.catalog.service

import com.fitlyfe.fitlyfe_backend.api.catalog.client.OpenFoodFactsClient
import com.fitlyfe.fitlyfe_backend.api.catalog.client.UsdaFoodDataClient
import com.fitlyfe.fitlyfe_backend.api.catalog.dto.FoodSearchResult
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class FoodCatalogService(
    private val foodEntryRepository: FoodEntryRepository,
    private val openFoodFactsClient: OpenFoodFactsClient,
    private val usdaFoodDataClient: UsdaFoodDataClient,
    @Value("\${usda.search-fallback-threshold}") private val fallbackThreshold: Int
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    /**
     * Searches the local catalog. If local results fall below [fallbackThreshold],
     * queries the USDA FoodData Central API, persists any new entries, and
     * returns the merged result set.
     *
     * The USDA HTTP call intentionally runs outside any transaction to avoid
     * holding a DB connection open during a network round-trip.
     */
    fun search(query: String, types: List<FoodEntryType>?, limit: Int, offset: Int): FoodSearchResult {
        val localTotal = countLocal(query, types)

        if (localTotal >= fallbackThreshold) {
            val localItems = searchLocal(query, types, limit, offset)
            return FoodSearchResult(items = localItems, total = localTotal, hasMore = (offset + limit) < localTotal)
        }

        // Local results are sparse — call USDA API (outside transaction)
        logger.debug("Local search for '{}' returned {} results (threshold {}), querying USDA API", query, localTotal, fallbackThreshold)
        val usdaResults = usdaFoodDataClient.search(query)

        // Persist in a separate transaction
        val saved = persistNewUsdaEntries(usdaResults)

        if (saved.isEmpty()) {
            val localItems = searchLocal(query, types, limit, offset)
            return FoodSearchResult(items = localItems, total = localTotal, hasMore = false)
        }

        // Re-query now that new entries are committed
        val refreshedTotal = countLocal(query, types)
        val refreshedItems = searchLocal(query, types, limit, offset)
        return FoodSearchResult(
            items = refreshedItems,
            total = refreshedTotal,
            hasMore = (offset + limit) < refreshedTotal
        )
    }

    @Transactional(readOnly = true)
    fun searchLocal(query: String, types: List<FoodEntryType>?, limit: Int, offset: Int): List<FoodEntryEntity> =
        foodEntryRepository.searchByName(query, types, limit, offset)

    @Transactional(readOnly = true)
    fun countLocal(query: String, types: List<FoodEntryType>?): Long =
        foodEntryRepository.countSearchResults(query, types)

    @Transactional(readOnly = true)
    fun findById(id: UUID): FoodEntryEntity? {
        return foodEntryRepository.findById(id).orElse(null)
    }

    /**
     * Looks up a product by barcode.
     * Strategy: local DB first, then Open Food Facts fallback.
     * If found externally, the product is stored locally for future lookups.
     */
    @Transactional
    fun findByBarcode(barcode: String): FoodEntryEntity? {
        val local = foodEntryRepository.findByBarcode(barcode)
        if (local != null) {
            logger.debug("Barcode {} found in local database", barcode)
            return local
        }

        val external = openFoodFactsClient.fetchByBarcode(barcode)
        if (external == null) {
            logger.debug("Barcode {} not found in Open Food Facts", barcode)
            return null
        }

        logger.info("Barcode {} fetched from Open Food Facts, storing locally", barcode)
        return foodEntryRepository.save(external)
    }

    /**
     * Filters out USDA entries that are already in the local DB (by externalId),
     * then saves and returns the new ones.
     */
    private fun persistNewUsdaEntries(candidates: List<FoodEntryEntity>): List<FoodEntryEntity> {
        if (candidates.isEmpty()) return emptyList()

        val existingIds = candidates
            .mapNotNull { it.externalId }
            .filter { it.isNotBlank() }
            .let { ids ->
                if (ids.isEmpty()) return@let emptySet()
                ids.filter { id ->
                    foodEntryRepository.findByExternalIdAndEntrySource(id, FoodEntrySource.USDA) != null
                }.toSet()
            }

        val newEntries = candidates.filter { it.externalId !in existingIds }
        if (newEntries.isEmpty()) return emptyList()

        logger.info("Persisting {} new USDA entries from API fallback", newEntries.size)
        return foodEntryRepository.saveAll(newEntries)
    }
}
