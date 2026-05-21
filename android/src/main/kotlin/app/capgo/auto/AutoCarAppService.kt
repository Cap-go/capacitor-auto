package app.capgo.auto

import android.content.Intent
import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.validation.HostValidator

class AutoCarAppService : CarAppService() {
    override fun createHostValidator(): HostValidator {
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

        return if (isDebuggable) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            HostValidator.Builder(applicationContext)
                .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
                .build()
        }
    }

    override fun onCreateSession(): Session {
        AutoBridge.setConnected(true)
        return AutoSession()
    }

    override fun onDestroy() {
        AutoBridge.setConnected(false)
        super.onDestroy()
    }
}

class AutoSession : Session() {
    override fun onCreateScreen(intent: Intent): Screen {
        AutoBridge.setConnected(true)
        return AutoScreen(carContext)
    }
}

class AutoScreen(carContext: CarContext) : Screen(carContext) {
    init {
        AutoBridge.registerScreen(this)
    }

    @Suppress("DEPRECATION")
    override fun onGetTemplate(): Template {
        val template = AutoBridge.template
        val items = template.sections.flatMap { it.items }

        if (items.isEmpty()) {
            return MessageTemplate.Builder(template.emptyText)
                .setTitle(template.title)
                .build()
        }

        val itemList = ItemList.Builder().apply {
            items.forEach { item ->
                addItem(makeRow(item))
            }
        }.build()

        return ListTemplate.Builder()
            .setTitle(template.title)
            .setSingleList(itemList)
            .build()
    }

    fun refresh() {
        invalidate()
    }

    private fun makeRow(item: AutoTemplateItem): Row {
        return Row.Builder().apply {
            setTitle(item.title)
            item.subtitle?.let { addText(it) }
            if (item.enabled) {
                setOnClickListener {
                    AutoBridge.receiveAction(item)
                }
            }
        }.build()
    }
}
