package app.capgo.auto

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import org.json.JSONException
import org.json.JSONObject

class AutoStore private constructor(context: Context) {
    fun interface Listener {
        fun onAutoStoreUpdated(key: String, value: JSONObject?, transient: Boolean)
    }

    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val listeners = CopyOnWriteArrayList<Listener>()
    private val transientValues = ConcurrentHashMap<String, JSONObject>()

    fun addListener(listener: Listener) {
        listeners.addIfAbsent(listener)
    }

    fun removeListener(listener: Listener) {
        listeners.remove(listener)
    }

    fun save(key: String, value: JSONObject) {
        prefs.edit().putString(key, value.toString()).apply()
        notifyChanged(key, value, false)
    }

    fun remove(key: String) {
        prefs.edit().remove(key).apply()
        notifyChanged(key, null, false)
    }

    fun load(key: String): JSONObject? {
        val raw = prefs.getString(key, null) ?: return null

        return try {
            JSONObject(raw)
        } catch (_: JSONException) {
            null
        }
    }

    fun setTransient(key: String, value: JSONObject?) {
        val previous = if (value == null) transientValues.remove(key) else transientValues.put(key, value)
        if (previous?.toString() != value?.toString()) {
            notifyChanged(key, value, true)
        }
    }

    fun getTransient(key: String): JSONObject? {
        return transientValues[key]
    }

    private fun notifyChanged(key: String, value: JSONObject?, transient: Boolean) {
        mainHandler.post {
            listeners.forEach { listener ->
                listener.onAutoStoreUpdated(key, value, transient)
            }
        }
    }

    companion object {
        private const val PREFS_NAME = "capgo_auto_store"

        @Volatile
        private var instance: AutoStore? = null

        @JvmStatic
        fun get(context: Context): AutoStore {
            return instance ?: synchronized(AutoStore::class.java) {
                instance ?: AutoStore(context).also { instance = it }
            }
        }
    }
}
