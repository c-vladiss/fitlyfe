package com.fitlyfe.fitlyfe_backend.api.catalog.client

import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntrySource
import com.fitlyfe.fitlyfe_backend.api.catalog.entity.FoodEntryType
import org.assertj.core.api.Assertions.assertThat
import org.assertj.core.data.Offset
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.http.HttpMethod
import org.springframework.http.MediaType
import org.springframework.test.web.client.MockRestServiceServer
import org.springframework.test.web.client.match.MockRestRequestMatchers.method
import org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo
import org.springframework.test.web.client.response.MockRestResponseCreators.withServerError
import org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess
import org.springframework.web.client.RestClient

class OpenFoodFactsClientTest {

    private lateinit var mockServer: MockRestServiceServer
    private lateinit var client: OpenFoodFactsClient

    @BeforeEach
    fun setUp() {
        val builder = RestClient.builder()
        mockServer = MockRestServiceServer.bindTo(builder).build()
        client = OpenFoodFactsClient(builder)
    }

    @Test
    fun `fetchByBarcode happy path - maps OFF response to FoodEntryEntity`() {
        val barcode = "3017620422003"
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/$barcode")))
            .andExpect(method(HttpMethod.GET))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "Nutella",
                        "brands": "Ferrero",
                        "serving_size": "15g",
                        "nutriments": {
                          "energy-kcal_100g": 539.0,
                          "proteins_100g": 6.3,
                          "carbohydrates_100g": 57.5,
                          "fat_100g": 30.9,
                          "fiber_100g": 3.4,
                          "sugars_100g": 56.3,
                          "saturated-fat_100g": 10.6,
                          "sodium_100g": 0.041,
                          "potassium_100g": 0.407
                        }
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode(barcode)

        assertThat(result).isNotNull
        assertThat(result!!.name).isEqualTo("Nutella")
        assertThat(result.brand).isEqualTo("Ferrero")
        assertThat(result.barcode).isEqualTo(barcode)
        assertThat(result.entryType).isEqualTo(FoodEntryType.PRODUCT)
        assertThat(result.entrySource).isEqualTo(FoodEntrySource.OPEN_FOOD_FACTS)
        assertThat(result.externalId).isEqualTo(barcode)
        assertThat(result.verified).isFalse()
        assertThat(result.servingSizeG).isEqualTo(15.0)
        assertThat(result.caloriesPer100g).isEqualTo(539.0)
        assertThat(result.proteinPer100g).isEqualTo(6.3)
        assertThat(result.carbsPer100g).isEqualTo(57.5)
        assertThat(result.fatPer100g).isEqualTo(30.9)
        assertThat(result.fiberPer100g).isEqualTo(3.4)
        assertThat(result.sugarPer100g).isEqualTo(56.3)
        assertThat(result.saturatedFatPer100g).isEqualTo(10.6)

        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode converts mineral units from grams to mg`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "Test Product",
                        "nutriments": {
                          "energy-kcal_100g": 100.0,
                          "sodium_100g": 0.5,
                          "potassium_100g": 0.35,
                          "calcium_100g": 0.12,
                          "iron_100g": 0.008,
                          "magnesium_100g": 0.025,
                          "zinc_100g": 0.003,
                          "phosphorus_100g": 0.15,
                          "cholesterol_100g": 0.03
                        }
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("1234567890")!!
        val micros = result.micronutrients!!

        assertThat(micros.sodiumMg).isCloseTo(500.0, Offset.offset(0.01))
        assertThat(micros.potassiumMg).isCloseTo(350.0, Offset.offset(0.01))
        assertThat(micros.calciumMg).isCloseTo(120.0, Offset.offset(0.01))
        assertThat(micros.ironMg).isCloseTo(8.0, Offset.offset(0.01))
        assertThat(micros.magnesiumMg).isCloseTo(25.0, Offset.offset(0.01))
        assertThat(micros.zincMg).isCloseTo(3.0, Offset.offset(0.01))
        assertThat(micros.phosphorusMg).isCloseTo(150.0, Offset.offset(0.01))
        assertThat(micros.cholesterolMg).isCloseTo(30.0, Offset.offset(0.01))

        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode converts vitamin units correctly`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "Vitamin Food",
                        "nutriments": {
                          "energy-kcal_100g": 100.0,
                          "vitamin-a_100g": 0.0009,
                          "vitamin-c_100g": 0.06,
                          "vitamin-d_100g": 0.000015,
                          "vitamin-e_100g": 0.01,
                          "vitamin-b12_100g": 0.0000024
                        }
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("9876543210")!!
        val micros = result.micronutrients!!

        // vitaminA: g -> mcg (*1_000_000)
        assertThat(micros.vitaminAMcg).isCloseTo(900.0, Offset.offset(0.01))
        // vitaminC: g -> mg (*1000)
        assertThat(micros.vitaminCMg).isCloseTo(60.0, Offset.offset(0.01))
        // vitaminD: g -> mcg (*1_000_000)
        assertThat(micros.vitaminDMcg).isCloseTo(15.0, Offset.offset(0.01))
        // vitaminE: g -> mg (*1000)
        assertThat(micros.vitaminEMg).isCloseTo(10.0, Offset.offset(0.01))
        // vitaminB12: g -> mcg (*1_000_000)
        assertThat(micros.vitaminB12Mcg).isCloseTo(2.4, Offset.offset(0.01))

        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode parses various serving size formats`() {
        val testCases = mapOf(
            "30g" to 30.0,
            "100 g" to 100.0,
            "1 slice (25g)" to 25.0,
            "2.5g" to 2.5
        )

        for ((servingSize, expected) in testCases) {
            val builder = RestClient.builder()
            val server = MockRestServiceServer.bindTo(builder).build()
            val testClient = OpenFoodFactsClient(builder)

            server.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
                .andRespond(
                    withSuccess(
                        """
                        {
                          "status": 1,
                          "product": {
                            "product_name": "Test",
                            "serving_size": "$servingSize",
                            "nutriments": {"energy-kcal_100g": 100.0}
                          }
                        }
                        """.trimIndent(),
                        MediaType.APPLICATION_JSON
                    )
                )

            val result = testClient.fetchByBarcode("000")
            assertThat(result!!.servingSizeG)
                .describedAs("Serving size '$servingSize' should parse to $expected")
                .isEqualTo(expected)

            server.verify()
        }
    }

    @Test
    fun `fetchByBarcode returns null serving size for unparseable formats`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "Test",
                        "serving_size": "1 cup",
                        "nutriments": {"energy-kcal_100g": 100.0}
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("000")
        assertThat(result!!.servingSizeG).isNull()
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode returns null when product not found (status != 1)`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """{"status": 0}""",
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("0000000000000")

        assertThat(result).isNull()
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode returns null when product is null`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """{"status": 1, "product": null}""",
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("0000000000000")

        assertThat(result).isNull()
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode defaults to Unknown Product when name is blank`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "  ",
                        "nutriments": {"energy-kcal_100g": 100.0}
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("111")

        assertThat(result!!.name).isEqualTo("Unknown Product")
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode defaults to Unknown Product when name is null`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "nutriments": {"energy-kcal_100g": 100.0}
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("222")

        assertThat(result!!.name).isEqualTo("Unknown Product")
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode returns null micronutrients when nutriments is null`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(
                withSuccess(
                    """
                    {
                      "status": 1,
                      "product": {
                        "product_name": "No Nutrients"
                      }
                    }
                    """.trimIndent(),
                    MediaType.APPLICATION_JSON
                )
            )

        val result = client.fetchByBarcode("333")

        assertThat(result!!.micronutrients).isNull()
        mockServer.verify()
    }

    @Test
    fun `fetchByBarcode returns null on API error`() {
        mockServer.expect(requestTo(org.hamcrest.Matchers.containsString("/api/v2/product/")))
            .andRespond(withServerError())

        val result = client.fetchByBarcode("444")

        assertThat(result).isNull()
        mockServer.verify()
    }
}
