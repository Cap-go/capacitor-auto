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

    fun save(key: String, value: JSONObject, synchronous: Boolean = false) {
        val snapshot = snapshot(value)
        val editor = prefs.edit().putString(key, snapshot.toString())
        val stored = if (synchronous) {
            editor.commit()
        } else {
            editor.apply()
            true
        }

        if (stored) {
            notifyChanged(key, snapshot, false)
        }
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
        val snapshot = value?.let { snapshot(it) }
        val previous = if (snapshot == null) transientValues.remove(key) else transientValues.put(key, snapshot)
        if (previous?.toString() != snapshot?.toString()) {
            notifyChanged(key, snapshot, true)
        }
    }

    fun getTransient(key: String): JSONObject? {
        return transientValues[key]?.let { snapshot(it) }
    }

    private fun notifyChanged(key: String, value: JSONObject?, transient: Boolean) {
        val snapshot = value?.let { snapshot(it) }
        mainHandler.post {
            listeners.forEach { listener ->
                listener.onAutoStoreUpdated(key, snapshot?.let { snapshot(it) }, transient)
            }
        }
    }

    private fun snapshot(value: JSONObject): JSONObject {
        return JSONObject(value.toString())
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
