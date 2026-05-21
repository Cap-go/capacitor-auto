package app.capgo.auto

import com.getcapacitor.JSObject
import java.lang.ref.WeakReference
import java.util.concurrent.CopyOnWriteArrayList
import org.json.JSONObject

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
    companion object {
        val fallback = AutoTemplate(
            title = "Auto",
            sections = emptyList(),
            emptyText = "Open the app to configure Auto.",
        )
    }
}

class Auto {
    fun getPluginVersion(): String {
        return "native"
    }
}

internal object AutoBridge {
    private var plugin: AutoPlugin? = null
    private val pendingEvents = mutableListOf<Pair<String, JSObject>>()
    private val screens = CopyOnWriteArrayList<WeakReference<AutoScreen>>()

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

    fun registerScreen(screen: AutoScreen) {
        screens.add(WeakReference(screen))
    }

    fun setTemplate(template: AutoTemplate) {
        this.template = template
        refreshScreens()
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
}
