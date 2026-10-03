package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.test.web.client.MockRestServiceServer
import org.springframework.test.web.client.match.MockRestRequestMatchers.method
import org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo
import org.springframework.test.web.client.match.MockRestRequestMatchers.queryParam
import org.springframework.test.web.client.response.MockRestResponseCreators.withServerError
import org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess
import org.springframework.web.client.RestClient

class UsdaFoodDataClientTest {

    private lateinit var mockServer: MockRestServiceServer
    private lateinit var client: UsdaFoodDataClient

    @BeforeEach
    fun setUp() {
        val builder = RestClient.builder()
        mockServer = MockRestServiceServer.bindTo(builder).build()
        client = UsdaFoodDataClient(builder, "test-api-key")
    }

    @Test
    fun `search happy path - maps USDA response to FoodEntryEntity`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andExpect(method(HttpMethod.GET))
            .andExpect(queryParam("query", "chicken"))
            .andExpect(queryParam("api_key", "test-api-key"))
            .andRespond(
                withSuccess(
                    """
                    {
                      "foods": [
                        {
                          "fdcId": 171077,
                          "description": "Chicken, breast, roasted",
                          "foodCategory": "Poultry Products",
                          "foodNutrients": [
                            {"nutrientId": 1008, "value": 165.0},
                            {"nutrientId": 1003, "value": 31.0},
                            {"nutrientId": 1004, "value": 3.6},
                            {"nutrientId": 1005, "value": 0.0},
                            {"nutrientId": 1079, "value": 0.0},
                            {"nutrientId": 2000, "value": 0.0},
                            {"nutrientId": 1258, "value": 1.0},
                            {"nutrientId": 1093, "value": 74.0},
                            {"nutrientId": 1092, "value": 256.0}
                          ]
                        }
                      ],
                      "totalHits": 1
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("chicken")

        assertThat(results).hasSize(1)
        val entry = results[0]
        assertThat(entry.name).isEqualTo("Chicken, breast, roasted")
        assertThat(entry.entryType).isEqualTo(FoodEntryType.FOOD)
        assertThat(entry.entrySource).isEqualTo(FoodEntrySource.USDA)
        assertThat(entry.externalId).isEqualTo("171077")
        assertThat(entry.verified).isTrue()
        assertThat(entry.caloriesPer100g).isEqualTo(165.0)
        assertThat(entry.proteinPer100g).isEqualTo(31.0)
        assertThat(entry.fatPer100g).isEqualTo(3.6)
        assertThat(entry.carbsPer100g).isEqualTo(0.0)
        assertThat(entry.fiberPer100g).isEqualTo(0.0)
        assertThat(entry.sugarPer100g).isEqualTo(0.0)
        assertThat(entry.saturatedFatPer100g).isEqualTo(1.0)
        assertThat(entry.micronutrients).isNotNull
        assertThat(entry.micronutrients!!.sodiumMg).isEqualTo(74.0)
        assertThat(entry.micronutrients!!.potassiumMg).isEqualTo(256.0)

        mockServer.verify()
    }

    @Test
    fun `search filters entries without calories or protein`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "foods": [
                        {
                          "fdcId": 100,
                          "description": "Water, tap",
                          "foodNutrients": [
                            {"nutrientId": 1005, "value": 0.0}
                          ]
                        }
                      ]
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("water")

        assertThat(results).isEmpty()
        mockServer.verify()
    }

    @Test
    fun `search filters entries with blank description`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "foods": [
                        {
                          "fdcId": 200,
                          "description": "  ",
                          "foodNutrients": [
                            {"nutrientId": 1008, "value": 100.0}
                          ]
                        },
                        {
                          "fdcId": 201,
                          "description": null,
                          "foodNutrients": [
                            {"nutrientId": 1008, "value": 100.0}
                          ]
                        }
                      ]
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("blank")

        assertThat(results).isEmpty()
        mockServer.verify()
    }

    @Test
    fun `search maps all 19 micronutrient IDs correctly`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "foods": [
                        {
                          "fdcId": 300,
                          "description": "Superfood",
                          "foodNutrients": [
                            {"nutrientId": 1008, "value": 200.0},
                            {"nutrientId": 1093, "value": 100.0},
                            {"nutrientId": 1092, "value": 200.0},
                            {"nutrientId": 1087, "value": 300.0},
                            {"nutrientId": 1089, "value": 5.0},
                            {"nutrientId": 1090, "value": 50.0},
                            {"nutrientId": 1095, "value": 3.0},
                            {"nutrientId": 1091, "value": 150.0},
                            {"nutrientId": 1106, "value": 900.0},
                            {"nutrientId": 1162, "value": 60.0},
                            {"nutrientId": 1114, "value": 15.0},
                            {"nutrientId": 1109, "value": 10.0},
                            {"nutrientId": 1185, "value": 120.0},
                            {"nutrientId": 1175, "value": 1.3},
                            {"nutrientId": 1178, "value": 2.4},
                            {"nutrientId": 1190, "value": 400.0},
                            {"nutrientId": 1167, "value": 16.0},
                            {"nutrientId": 1165, "value": 1.2},
                            {"nutrientId": 1166, "value": 1.3},
                            {"nutrientId": 1253, "value": 50.0}
                          ]
                        }
                      ]
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("superfood")
        assertThat(results).hasSize(1)

        val micros = results[0].micronutrients!!
        assertThat(micros.sodiumMg).isEqualTo(100.0)
        assertThat(micros.potassiumMg).isEqualTo(200.0)
        assertThat(micros.calciumMg).isEqualTo(300.0)
        assertThat(micros.ironMg).isEqualTo(5.0)
        assertThat(micros.magnesiumMg).isEqualTo(50.0)
        assertThat(micros.zincMg).isEqualTo(3.0)
        assertThat(micros.phosphorusMg).isEqualTo(150.0)
        assertThat(micros.vitaminAMcg).isEqualTo(900.0)
        assertThat(micros.vitaminCMg).isEqualTo(60.0)
        assertThat(micros.vitaminDMcg).isEqualTo(15.0)
        assertThat(micros.vitaminEMg).isEqualTo(10.0)
        assertThat(micros.vitaminKMcg).isEqualTo(120.0)
        assertThat(micros.vitaminB6Mg).isEqualTo(1.3)
        assertThat(micros.vitaminB12Mcg).isEqualTo(2.4)
        assertThat(micros.folateMcg).isEqualTo(400.0)
        assertThat(micros.niacinMg).isEqualTo(16.0)
        assertThat(micros.thiaminMg).isEqualTo(1.2)
        assertThat(micros.riboflavinMg).isEqualTo(1.3)
        assertThat(micros.cholesterolMg).isEqualTo(50.0)

        mockServer.verify()
    }

    @Test
    fun `search returns null micronutrients when no micro IDs are present`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "foods": [
                        {
                          "fdcId": 400,
                          "description": "Simple food",
                          "foodNutrients": [
                            {"nutrientId": 1008, "value": 100.0},
                            {"nutrientId": 1003, "value": 10.0}
                          ]
                        }
                      ]
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("simple")

        assertThat(results).hasSize(1)
        assertThat(results[0].micronutrients).isNull()
        mockServer.verify()
    }

    @Test
    fun `search returns empty list for empty response`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """{"foods": [], "totalHits": 0}""",
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("nonexistent")

        assertThat(results).isEmpty()
        mockServer.verify()
    }

    @Test
    fun `search returns empty list when foods is null`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(
                withSuccess(
                    """{"totalHits": 0}""",
                    MediaType.APPLICATION_JSON
                )
            )

        val results = client.search("nonexistent")

        assertThat(results).isEmpty()
        mockServer.verify()
    }

    @Test
    fun `search returns empty list on API error`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/foods/search")))
            .andRespond(withServerError())

        val results = client.search("chicken")

        assertThat(results).isEmpty()
        mockServer.verify()
    }
}
