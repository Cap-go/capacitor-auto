package app.capgo.auto

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import org.json.JSONObject

@CapacitorPlugin(name = "Auto")
class AutoPlugin : Plugin() {
    private val implementation = Auto()

    override fun load() {
        AutoBridge.configure(context)
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
        val template = AutoTemplate.fromJson(call.data)
        if (template == null) {
            call.reject("title is required")
            return
        }

        AutoBridge.setTemplate(template)
        call.resolve()
    }

    @PluginMethod
    fun setState(call: PluginCall) {
        val key = getStateKey(call) ?: return

        val value = call.getObject("value")
        if (value == null) {
            call.reject("value is required for key=$key")
            return
        }

        AutoBridge.setState(key, value)
        call.resolve()
    }

    @PluginMethod
    fun getState(call: PluginCall) {
        val key = getStateKey(call) ?: return

        call.resolve(stateResult(key, AutoBridge.getState(key)))
    }

    @PluginMethod
    fun removeState(call: PluginCall) {
        val key = getStateKey(call) ?: return

        AutoBridge.removeState(key)
        call.resolve()
    }

    @PluginMethod
    fun setTransientState(call: PluginCall) {
        val key = getStateKey(call) ?: return

        val value = call.getObject("value")
        if (value == null) {
            call.reject("value is required for key=$key")
            return
        }

        AutoBridge.setTransientState(key, value)
        call.resolve()
    }

    @PluginMethod
    fun getTransientState(call: PluginCall) {
        val key = getStateKey(call) ?: return

        call.resolve(stateResult(key, AutoBridge.getTransientState(key)))
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

    private fun getStateKey(call: PluginCall): String? {
        val key = call.getString("key")
        if (key.isNullOrBlank()) {
            call.reject("key is required")
            return null
        }

        if (key == ROOT_TEMPLATE_STATE_KEY) {
            call.reject("key is reserved: $ROOT_TEMPLATE_STATE_KEY")
            return null
        }

        return key
    }

    private fun stateResult(key: String, value: JSONObject?): JSObject {
        return JSObject().apply {
            put("key", key)
            value?.let { put("value", it) }
        }
    }
}
