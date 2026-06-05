package app.capgo.auto

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class AutoTemplateTest {
    @Test
    fun templateRoundTripsThroughJson() {
        val payload = JSONObject().put("routeId", "main")
        val template = AutoTemplate(
            title = "Drive",
            sections = listOf(
                AutoTemplateSection(
                    header = "Routes",
                    items = listOf(
                        AutoTemplateItem(
                            id = "start",
                            title = "Start route",
                            subtitle = "Main",
                            payload = payload,
                            enabled = true,
                        ),
                    ),
                ),
            ),
            emptyText = "No routes",
        )

        val restored = AutoTemplate.fromJson(template.toJson())

        assertNotNull(restored)
        assertEquals("Drive", restored?.title)
        assertEquals("Routes", restored?.sections?.first()?.header)
        assertEquals("start", restored?.sections?.first()?.items?.first()?.id)
        assertEquals("main", restored?.sections?.first()?.items?.first()?.payload?.getString("routeId"))
    }

    @Test
    fun invalidRowsAreSkipped() {
        val rawTemplate = JSONObject()
            .put("title", "Drive")
            .put(
                "sections",
                JSONArray().put(
                    JSONObject().put(
                        "items",
                        JSONArray()
                            .put(JSONObject().put("title", "Missing id"))
                            .put(JSONObject().put("id", "valid").put("title", "Valid")),
                    ),
                ),
            )

        val restored = AutoTemplate.fromJson(rawTemplate)

        assertEquals(1, restored?.sections?.first()?.items?.size)
        assertEquals("valid", restored?.sections?.first()?.items?.first()?.id)
    }
}
