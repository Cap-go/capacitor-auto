package app.capgo.auto

import android.content.Context
import com.getcapacitor.JSObject
import java.lang.ref.WeakReference
import java.util.concurrent.CopyOnWriteArrayList
import org.json.JSONArray
import org.json.JSONObject

internal const val ROOT_TEMPLATE_STATE_KEY = "__capgo_auto_root_template"

data class AutoTemplateItem(
    val id: String,
    val title: String,
    val subtitle: String?,
    val payload: JSONObject?,
    val enabled: Boolean,
)

data class AutoTemplateSection(
    val header: String?,
    val items: List<AutoTemplateItem>,
)

data class AutoTemplate(
    val title: String,
    val sections: List<AutoTemplateSection>,
    val emptyText: String,
) {
    fun toJson(): JSObject {
        val sectionsJson = JSONArray()
        sections.forEach { section ->
            val sectionJson = JSONObject()
            section.header?.let { sectionJson.put("header", it) }

            val itemsJson = JSONArray()
            section.items.forEach { item ->
                val itemJson = JSONObject().apply {
                    put("id", item.id)
                    put("title", item.title)
                    item.subtitle?.let { put("subtitle", it) }
                    item.payload?.let { put("payload", it) }
                    put("enabled", item.enabled)
                }
                itemsJson.put(itemJson)
            }

            sectionJson.put("items", itemsJson)
            sectionsJson.put(sectionJson)
        }

        return JSObject().apply {
            put("title", title)
            put("sections", sectionsJson)
            put("emptyText", emptyText)
        }
    }

    companion object {
        val fallback = AutoTemplate(
            title = "Auto",
            sections = emptyList(),
            emptyText = "Open the app to configure Auto.",
        )

        fun fromJson(rawTemplate: JSONObject?): AutoTemplate? {
            if (rawTemplate == null) {
                return null
            }

            val title = rawTemplate.optString("title").takeIf { it.isNotBlank() } ?: return null
            return AutoTemplate(
                title = title,
                sections = parseSections(rawTemplate.optJSONArray("sections")),
                emptyText = rawTemplate.optString("emptyText").takeIf { it.isNotBlank() } ?: "No actions available.",
            )
        }

        private fun parseSections(rawSections: JSONArray?): List<AutoTemplateSection> {
            if (rawSections == null) {
                return emptyList()
            }

            return buildList {
                for (sectionIndex in 0 until rawSections.length()) {
                    val rawSection = rawSections.optJSONObject(sectionIndex) ?: continue
                    add(
                        AutoTemplateSection(
                            header = rawSection.optString("header").takeIf { it.isNotBlank() },
                            items = parseItems(rawSection.optJSONArray("items")),
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
}

class Auto {
    fun getPluginVersion(): String {
        return "native"
    }
}

internal object AutoBridge {
    private var plugin: AutoPlugin? = null
    private var store: AutoStore? = null
    private val pendingEvents = mutableListOf<Pair<String, JSObject>>()
    private val screens = CopyOnWriteArrayList<WeakReference<AutoScreen>>()
    private val storeListener = AutoStore.Listener { key, value, transient ->
        if (key != ROOT_TEMPLATE_STATE_KEY && plugin != null) {
            emitStateChanged(key, value, transient)
        }
    }

    var template: AutoTemplate = AutoTemplate.fallback
        private set

    var connected: Boolean = false
        private set

    var lastMessage: JSObject? = null
        private set

    fun attach(plugin: AutoPlugin) {
        this.plugin = plugin
        emitConnection()

        pendingEvents.forEach { (name, data) ->
            plugin.emitEvent(name, data)
        }
        pendingEvents.clear()
    }

    fun detach(plugin: AutoPlugin) {
        if (this.plugin === plugin) {
            this.plugin = null
        }
    }

    fun configure(context: Context) {
        val nextStore = AutoStore.get(context)
        if (store !== nextStore) {
            store?.removeListener(storeListener)
            store = nextStore
            nextStore.addListener(storeListener)
        }

        AutoTemplate.fromJson(nextStore.load(ROOT_TEMPLATE_STATE_KEY))?.let {
            template = it
        }
    }

    fun registerScreen(screen: AutoScreen) {
        screens.add(WeakReference(screen))
    }

    fun setTemplate(template: AutoTemplate) {
        this.template = template
        store?.save(ROOT_TEMPLATE_STATE_KEY, template.toJson(), synchronous = true)
        refreshScreens()
    }

    fun setState(key: String, value: JSONObject) {
        requireStore().save(key, value)
    }

    fun getState(key: String): JSONObject? {
        return requireStore().load(key)
    }

    fun removeState(key: String) {
        requireStore().remove(key)
    }

    fun setTransientState(key: String, value: JSONObject) {
        requireStore().setTransient(key, value)
    }

    fun getTransientState(key: String): JSONObject? {
        return requireStore().getTransient(key)
    }

    fun setConnected(connected: Boolean) {
        this.connected = connected
        emitConnection()
    }

    fun receiveAction(item: AutoTemplateItem) {
        val data = JSObject().apply {
            put("id", item.id)
            put("title", item.title)
            put("platform", "android")
            item.payload?.let { put("payload", it) }
        }

        emit("carAction", data)
    }

    fun receiveMessage(type: String, payload: JSONObject?) {
        val data = JSObject().apply {
            put("type", type)
            put("platform", "android")
            payload?.let { put("payload", it) }
        }

        lastMessage = data
        emit("messageReceived", data)
    }

    private fun emitStateChanged(key: String, value: JSONObject?, transient: Boolean) {
        val data = JSObject().apply {
            put("key", key)
            put("platform", "android")
            put("transient", transient)
            value?.let { put("value", it) }
        }
        emit("stateChanged", data)
    }

    private fun emitConnection() {
        val data = JSObject().apply {
            put("connected", connected)
            put("platform", "android")
        }
        emit("connectionChanged", data)
    }

    private fun emit(eventName: String, data: JSObject) {
        val currentPlugin = plugin
        if (currentPlugin == null) {
            pendingEvents.add(eventName to data)
            return
        }

        currentPlugin.emitEvent(eventName, data)
    }

    private fun refreshScreens() {
        screens.removeAll { reference ->
            val screen = reference.get()
            if (screen == null) {
                true
            } else {
                screen.refresh()
                false
            }
        }
    }

    private fun requireStore(): AutoStore {
        return store ?: throw IllegalStateException("AutoBridge is not configured with an Android context")
    }
}
