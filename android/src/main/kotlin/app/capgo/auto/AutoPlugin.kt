package app.capgo.auto

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONArray

@CapacitorPlugin(name = "Auto")
class AutoPlugin : Plugin() {
    private val implementation = Auto()

    override fun load() {
        AutoBridge.attach(this)
    }

    override fun handleOnDestroy() {
        AutoBridge.detach(this)
        super.handleOnDestroy()
    }

    @PluginMethod
    fun isAvailable(call: PluginCall) {
        val ret = JSObject().apply {
            put("available", true)
            put("connected", AutoBridge.connected)
            put("platform", "android")
        }
        call.resolve(ret)
    }

    @PluginMethod
    fun setRootTemplate(call: PluginCall) {
        val title = call.getString("title")
        if (title.isNullOrBlank()) {
            call.reject("title is required")
            return
        }

        AutoBridge.setTemplate(
            AutoTemplate(
                title = title,
                sections = parseSections(call.getArray("sections")),
                emptyText = call.getString("emptyText") ?: "No actions available.",
            ),
        )
        call.resolve()
    }

    @PluginMethod
    fun sendMessage(call: PluginCall) {
        val type = call.getString("type")
        if (type.isNullOrBlank()) {
            call.reject("type is required")
            return
        }

        AutoBridge.receiveMessage(type, call.getObject("payload"))
        call.resolve()
    }

    @PluginMethod
    fun getPluginVersion(call: PluginCall) {
        val ret = JSObject().apply {
            put("version", implementation.getPluginVersion())
        }
        call.resolve(ret)
    }

    internal fun emitEvent(eventName: String, data: JSObject) {
        notifyListeners(eventName, data, true)
    }

    private fun parseSections(rawSections: JSONArray?): List<AutoTemplateSection> {
        if (rawSections == null) {
            return emptyList()
        }

        return buildList {
            for (sectionIndex in 0 until rawSections.length()) {
                val rawSection = rawSections.optJSONObject(sectionIndex) ?: continue
                val rawItems = rawSection.optJSONArray("items")
                val items = parseItems(rawItems)

                add(
                    AutoTemplateSection(
                        header = rawSection.optString("header").takeIf { it.isNotBlank() },
                        items = items,
                    ),
                )
            }
        }
    }

    private fun parseItems(rawItems: JSONArray?): List<AutoTemplateItem> {
        if (rawItems == null) {
            return emptyList()
        }

        return buildList {
            for (itemIndex in 0 until rawItems.length()) {
                val rawItem = rawItems.optJSONObject(itemIndex) ?: continue
                val id = rawItem.optString("id")
                val title = rawItem.optString("title")

                if (id.isBlank() || title.isBlank()) {
                    continue
                }

                add(
                    AutoTemplateItem(
                        id = id,
                        title = title,
                        subtitle = rawItem.optString("subtitle").takeIf { it.isNotBlank() },
                        payload = rawItem.optJSONObject("payload"),
                        enabled = if (rawItem.has("enabled")) rawItem.optBoolean("enabled") else true,
                    ),
                )
            }
        }
    }
}
