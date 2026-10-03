package com.fitlyfe.fitlyfe_backend.api.catalog.service

import com.fitlyfe.fitlyfe_backend.api.catalog.client.OpenFoodFactsClient
import com.fitlyfe.fitlyfe_backend.api.catalog.client.UsdaFoodDataClient
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Nested
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.Mock
import org.mockito.Mockito.verifyNoInteractions
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.*
import java.util.*

@ExtendWith(MockitoExtension::class)
class FoodCatalogServiceTest {

    @Mock
    private lateinit var foodEntryRepository: FoodEntryRepository

    @Mock
    private lateinit var openFoodFactsClient: OpenFoodFactsClient

    @Mock
    private lateinit var usdaFoodDataClient: UsdaFoodDataClient

    private lateinit var service: FoodCatalogService

    private val fallbackThreshold = 5

    @BeforeEach
    fun setUp() {
        service = FoodCatalogService(
            foodEntryRepository,
            openFoodFactsClient,
            usdaFoodDataClient,
            fallbackThreshold
        )
    }

    private fun foodEntry(
        name: String,
        source: FoodEntrySource = FoodEntrySource.USDA,
        externalId: String? = null,
        barcode: String? = null
    ) = FoodEntryEntity(
        name = name,
        entryType = FoodEntryType.FOOD,
        entrySource = source,
        externalId = externalId,
        barcode = barcode,
        caloriesPer100g = 100.0,
        proteinPer100g = 10.0
    )

    @Nested
    inner class Search {

        @Test
        fun `returns local results when count meets threshold - USDA not called`() {
            whenever(foodEntryRepository.countSearchResults("chicken", null)).thenReturn(5L)
            whenever(foodEntryRepository.searchByName("chicken", null, 25, 0))
                .thenReturn(listOf(foodEntry("Chicken")))

            val result = service.search("chicken", null, 25, 0)

            assertThat(result.items).hasSize(1)
            assertThat(result.total).isEqualTo(5L)
            verifyNoInteractions(usdaFoodDataClient)
        }

        @Test
        fun `calls USDA when local count below threshold and persists new entries`() {
            val usdaEntry = foodEntry("USDA Chicken", externalId = "12345")

            whenever(foodEntryRepository.countSearchResults("chicken", null))
                .thenReturn(2L, 7L)  // first call: below threshold, second: after persist
            whenever(foodEntryRepository.searchByName("chicken", null, 25, 0))
                .thenReturn(listOf(foodEntry("Chicken")))  // returned on second query
            whenever(usdaFoodDataClient.search("chicken")).thenReturn(listOf(usdaEntry))
            whenever(foodEntryRepository.findByExternalIdAndEntrySource("12345", FoodEntrySource.USDA))
                .thenReturn(null)  // not a duplicate
            whenever(foodEntryRepository.saveAll(any<List<FoodEntryEntity>>()))
                .thenReturn(listOf(usdaEntry))

            val result = service.search("chicken", null, 25, 0)

            verify(usdaFoodDataClient).search("chicken")
            verify(foodEntryRepository).saveAll(any<List<FoodEntryEntity>>())
            assertThat(result.total).isEqualTo(7L)
        }

        @Test
        fun `does not re-save entries with existing externalId`() {
            val usdaEntry = foodEntry("USDA Chicken", externalId = "12345")
            val existingEntry = foodEntry("Existing Chicken", externalId = "12345")

            whenever(foodEntryRepository.countSearchResults("chicken", null)).thenReturn(2L)
            whenever(foodEntryRepository.searchByName("chicken", null, 25, 0))
                .thenReturn(listOf(foodEntry("Chicken")))
            whenever(usdaFoodDataClient.search("chicken")).thenReturn(listOf(usdaEntry))
            whenever(foodEntryRepository.findByExternalIdAndEntrySource("12345", FoodEntrySource.USDA))
                .thenReturn(existingEntry)  // already exists

            val result = service.search("chicken", null, 25, 0)

            verify(foodEntryRepository, never()).saveAll(any<List<FoodEntryEntity>>())
            assertThat(result.total).isEqualTo(2L)
            assertThat(result.hasMore).isFalse()
        }

        @Test
        fun `returns local results when USDA returns empty`() {
            val localEntry = foodEntry("Local Chicken")

            whenever(foodEntryRepository.countSearchResults("chicken", null)).thenReturn(2L)
            whenever(foodEntryRepository.searchByName("chicken", null, 25, 0))
                .thenReturn(listOf(localEntry))
            whenever(usdaFoodDataClient.search("chicken")).thenReturn(emptyList())

            val result = service.search("chicken", null, 25, 0)

            assertThat(result.items).containsExactly(localEntry)
            assertThat(result.total).isEqualTo(2L)
            assertThat(result.hasMore).isFalse()
        }

        @Test
        fun `returns local results when USDA API fails`() {
            val localEntry = foodEntry("Local Chicken")

            whenever(foodEntryRepository.countSearchResults("chicken", null)).thenReturn(2L)
            whenever(foodEntryRepository.searchByName("chicken", null, 25, 0))
                .thenReturn(listOf(localEntry))
            // Client already handles exceptions internally and returns emptyList()
            whenever(usdaFoodDataClient.search("chicken")).thenReturn(emptyList())

            val result = service.search("chicken", null, 25, 0)

            assertThat(result.items).containsExactly(localEntry)
            assertThat(result.total).isEqualTo(2L)
        }

        @Test
        fun `hasMore is true when local total exceeds offset plus limit`() {
            whenever(foodEntryRepository.countSearchResults("chicken", null)).thenReturn(50L)
            whenever(foodEntryRepository.searchByName("chicken", null, 10, 0))
                .thenReturn((1..10).map { foodEntry("Food $it") })

            val result = service.search("chicken", null, 10, 0)

            assertThat(result.hasMore).isTrue()
        }
    }

    @Nested
    inner class FindByBarcode {

        @Test
        fun `returns local result when found - OFF not called`() {
            val local = foodEntry("Local Product", barcode = "123")

            whenever(foodEntryRepository.findByBarcode("123")).thenReturn(local)

            val result = service.findByBarcode("123")

            assertThat(result).isEqualTo(local)
            verifyNoInteractions(openFoodFactsClient)
        }

        @Test
        fun `fetches from OFF and saves when not in local DB`() {
            val offEntry = foodEntry("OFF Product", source = FoodEntrySource.OPEN_FOOD_FACTS, barcode = "456")
            val savedEntry = offEntry.copy()

            whenever(foodEntryRepository.findByBarcode("456")).thenReturn(null)
            whenever(openFoodFactsClient.fetchByBarcode("456")).thenReturn(offEntry)
            whenever(foodEntryRepository.save(offEntry)).thenReturn(savedEntry)

            val result = service.findByBarcode("456")

            assertThat(result).isEqualTo(savedEntry)
            verify(foodEntryRepository).save(offEntry)
        }

        @Test
        fun `returns null when not in local DB and not in OFF`() {
            whenever(foodEntryRepository.findByBarcode("789")).thenReturn(null)
            whenever(openFoodFactsClient.fetchByBarcode("789")).thenReturn(null)

            val result = service.findByBarcode("789")

            assertThat(result).isNull()
        }

        @Test
        fun `returns null when not in local DB and OFF API fails`() {
            whenever(foodEntryRepository.findByBarcode("000")).thenReturn(null)
            // Client returns null on failure
            whenever(openFoodFactsClient.fetchByBarcode("000")).thenReturn(null)

            val result = service.findByBarcode("000")

            assertThat(result).isNull()
        }
    }

    @Nested
    inner class FindById {

        @Test
        fun `returns entity when found`() {
            val id = UUID.randomUUID()
            val entry = foodEntry("Test Food")

            whenever(foodEntryRepository.findById(id)).thenReturn(Optional.of(entry))

            val result = service.findById(id)

            assertThat(result).isEqualTo(entry)
        }

        @Test
        fun `returns null when not found`() {
            val id = UUID.randomUUID()

            whenever(foodEntryRepository.findById(id)).thenReturn(Optional.empty())

            val result = service.findById(id)

            assertThat(result).isNull()
        }
    }
}
