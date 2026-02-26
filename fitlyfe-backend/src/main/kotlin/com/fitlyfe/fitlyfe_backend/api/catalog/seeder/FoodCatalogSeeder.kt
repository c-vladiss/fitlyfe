package com.fitlyfe.fitlyfe_backend.api.catalog.seeder

import com.fasterxml.jackson.databind.ObjectMapper
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.repository.FoodEntryRepository
import org.slf4j.LoggerFactory
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional

/**
 * Seeds the food catalog from bundled JSON files on application startup.
 * Idempotent: skips if seed data already exists.
 *
 * Seed files expected at (on classpath):
 *   data/seeds/foods_seed.json    — generic foods (FOOD entries)
 *   data/seeds/products_seed.json — sample branded products (PRODUCT entries, optional)
 */
@Component
class FoodCatalogSeeder(
    private val foodEntryRepository: FoodEntryRepository,
    private val objectMapper: ObjectMapper
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    @EventListener(ApplicationReadyEvent::class)
    @Transactional
    fun seed() {
        val seededCount = foodEntryRepository.countByEntrySourceIn(
            listOf(FoodEntrySource.SEED, FoodEntrySource.USDA)
        )
        if (seededCount > 0) {
            logger.info("Food catalog already seeded ({} entries). Skipping.", seededCount)
            return
        }

        logger.info("Seeding food catalog...")
        val foodCount = seedFoods("data/seeds/foods_seed.json")
        val productCount = seedFoods("data/seeds/products_seed.json")
        logger.info("Food catalog seeding complete: {} foods, {} sample products.", foodCount, productCount)
    }

    private fun seedFoods(resourcePath: String): Int {
        val inputStream = javaClass.classLoader.getResourceAsStream(resourcePath) ?: run {
            logger.info("Seed file not present: {}. Skipping.", resourcePath)
            return 0
        }

        val dtos: List<FoodEntrySeedDto> = inputStream.use {
            objectMapper.readValue(
                it,
                objectMapper.typeFactory.constructCollectionType(List::class.java, FoodEntrySeedDto::class.java)
            )
        }

        val entities = dtos.map { it.toEntity() }
        foodEntryRepository.saveAll(entities)
        logger.info("Loaded {} entries from {}.", entities.size, resourcePath)
        return entities.size
    }
}
