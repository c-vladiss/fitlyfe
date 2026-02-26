package com.fitlyfe.fitlyfe_backend.api.catalog.repository

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryEntity
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import jakarta.persistence.EntityManager
import jakarta.persistence.PersistenceContext
import org.springframework.stereotype.Repository

@Repository
class FoodEntrySearchRepositoryImpl(
    @PersistenceContext private val entityManager: EntityManager
) : FoodEntrySearchRepository {

    override fun searchByName(
        query: String,
        types: List<FoodEntryType>?,
        limit: Int,
        offset: Int
    ): List<FoodEntryEntity> {
        val sql = buildSearchQuery(types, count = false)
        val nativeQuery = entityManager.createNativeQuery(sql, FoodEntryEntity::class.java)
        setSearchParameters(nativeQuery, query)
        nativeQuery.maxResults = limit
        nativeQuery.firstResult = offset

        @Suppress("UNCHECKED_CAST")
        return nativeQuery.resultList as List<FoodEntryEntity>
    }

    override fun countSearchResults(
        query: String,
        types: List<FoodEntryType>?
    ): Long {
        val sql = buildSearchQuery(types, count = true)
        val nativeQuery = entityManager.createNativeQuery(sql)
        setSearchParameters(nativeQuery, query)
        return (nativeQuery.singleResult as Number).toLong()
    }

    private fun buildSearchQuery(types: List<FoodEntryType>?, count: Boolean): String {
        // Safe: enum .name values are compile-time constants, not user input
        val typeFilter = if (!types.isNullOrEmpty()) {
            val typeValues = types.joinToString(",") { "'${it.name}'" }
            "AND entry_type IN ($typeValues)"
        } else ""

        val selectClause = if (count) "SELECT COUNT(*)" else "SELECT *"
        val orderClause = if (count) "" else """
            ORDER BY
                CASE
                    WHEN LOWER(name) = LOWER(:query) THEN 0
                    WHEN LOWER(name) LIKE LOWER(CONCAT(:query, '%')) THEN 1
                    ELSE 2
                END,
                similarity(name, :query) DESC
        """

        return """
            $selectClause FROM food_entries
            WHERE (
                LOWER(name) LIKE LOWER(CONCAT('%', :query, '%'))
                OR similarity(name, :query) > 0.2
            )
            $typeFilter
            $orderClause
        """.trimIndent()
    }

    private fun setSearchParameters(query: jakarta.persistence.Query, searchQuery: String) {
        query.setParameter("query", searchQuery)
    }
}
