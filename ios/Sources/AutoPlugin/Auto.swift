import Foundation

public struct AutoTemplateItem {
    let id: String
    let title: String
    let subtitle: String?
    let payload: [String: Any]?
    let enabled: Bool
}

public struct AutoTemplateSection {
    let header: String?
    let items: [AutoTemplateItem]
}

public struct AutoTemplate {
    let title: String
    let sections: [AutoTemplateSection]
    let emptyText: String

    static let fallback = AutoTemplate(
        title: "Auto",
        sections: [],
        emptyText: "Open the app to configure Auto."
    )

    func toDictionary() -> [String: Any] {
        [
            "title": title,
            "sections": sections.map { section in
                var sectionData: [String: Any] = [
                    "items": section.items.map { item in
                        var itemData: [String: Any] = [
                            "id": item.id,
                            "title": item.title,
                            "enabled": item.enabled
                        ]

                        if let subtitle = item.subtitle {
                            itemData["subtitle"] = subtitle
                        }
                        if let payload = item.payload {
                            itemData["payload"] = payload
                        }

                        return itemData
                    }
                ]

                if let header = section.header {
                    sectionData["header"] = header
                }

                return sectionData
            },
            "emptyText": emptyText
        ]
    }

    static func fromDictionary(_ rawTemplate: [String: Any]) -> AutoTemplate? {
        guard let title = rawTemplate["title"] as? String, !title.isEmpty else {
            return nil
        }

        return AutoTemplate(
            title: title,
            sections: parseSections(rawTemplate["sections"] as? [Any] ?? []),
            emptyText: rawTemplate["emptyText"] as? String ?? "No actions available."
        )
    }

    private static func parseSections(_ rawSections: [Any]) -> [AutoTemplateSection] {
        rawSections.compactMap { rawSection in
            guard let section = rawSection as? [String: Any] else {
                return nil
            }

            let rawItems = section["items"] as? [[String: Any]] ?? []
            let items = rawItems.compactMap(parseItem)

            return AutoTemplateSection(
                header: section["header"] as? String,
                items: items
            )
        }
    }

    private static func parseItem(_ rawItem: [String: Any]) -> AutoTemplateItem? {
        guard
            let id = rawItem["id"] as? String,
            let title = rawItem["title"] as? String,
            !id.isEmpty,
            !title.isEmpty
        else {
            return nil
        }

        return AutoTemplateItem(
            id: id,
            title: title,
            subtitle: rawItem["subtitle"] as? String,
            payload: rawItem["payload"] as? [String: Any],
            enabled: rawItem["enabled"] as? Bool ?? true
        )
    }
}

extension Notification.Name {
    static let capgoAutoTemplateChanged = Notification.Name("CapgoAutoTemplateChanged")
}

public final class AutoBridge {
    public static let shared = AutoBridge()

    private static let rootTemplateStateKey = "__capgo_auto_root_template"

    private weak var plugin: AutoPlugin?
    private var pendingEvents: [(String, [String: Any])] = []

    public private(set) var template = AutoTemplate.fallback
    public private(set) var connected = false
    public private(set) var lastMessage: [String: Any]?

    private init() {
        AutoStore.shared.addListener(self)
        loadStoredTemplate()
    }

    func attach(_ plugin: AutoPlugin) {
        self.plugin = plugin
        emit("connectionChanged", data: [
            "connected": connected,
            "platform": "ios"
        ])

        pendingEvents.forEach { name, data in
            plugin.emitEvent(name, data: data)
        }
        pendingEvents.removeAll()
    }

    func detach(_ plugin: AutoPlugin) {
        if self.plugin === plugin {
            self.plugin = nil
        }
    }

    func setTemplate(_ template: AutoTemplate) {
        self.template = template
        AutoStore.shared.save(Self.rootTemplateStateKey, template.toDictionary())
        NotificationCenter.default.post(name: .capgoAutoTemplateChanged, object: nil)
    }

    func reloadStoredTemplate() {
        loadStoredTemplate()
    }

    func setState(key: String, value: [String: Any]) {
        AutoStore.shared.save(key, value)
    }

    func getState(key: String) -> [String: Any]? {
        AutoStore.shared.load(key)
    }

    func removeState(key: String) {
        AutoStore.shared.remove(key)
    }

    func setTransientState(key: String, value: [String: Any]) {
        AutoStore.shared.setTransient(key, value)
    }

    func getTransientState(key: String) -> [String: Any]? {
        AutoStore.shared.getTransient(key)
    }

    func setConnected(_ connected: Bool) {
        self.connected = connected
        emit("connectionChanged", data: [
            "connected": connected,
            "platform": "ios"
        ])
    }

    func receiveAction(_ item: AutoTemplateItem) {
        var data: [String: Any] = [
            "id": item.id,
            "title": item.title,
            "platform": "ios"
        ]

        if let payload = item.payload {
            data["payload"] = payload
        }

        emit("carAction", data: data)
    }

    func receiveMessage(type: String, payload: [String: Any]?) {
        var data: [String: Any] = [
            "type": type,
            "platform": "ios"
        ]

        if let payload = payload {
            data["payload"] = payload
        }

        lastMessage = data
        emit("messageReceived", data: data)
    }

    private func emit(_ name: String, data: [String: Any]) {
        guard let plugin else {
            pendingEvents.append((name, data))
            return
        }

        plugin.emitEvent(name, data: data)
    }

    private func loadStoredTemplate() {
        guard
            let storedTemplate = AutoStore.shared.load(Self.rootTemplateStateKey),
            let template = AutoTemplate.fromDictionary(storedTemplate)
        else {
            return
        }

        self.template = template
    }
}

extension AutoBridge: AutoStoreListener {
    public func onAutoStoreUpdated(_ key: String, value: [String: Any]?, transient: Bool) {
        guard key != Self.rootTemplateStateKey else {
            return
        }

        var data: [String: Any] = [
            "key": key,
            "platform": "ios",
            "transient": transient
        ]

        if let value = value {
            data["value"] = value
        }

        emit("stateChanged", data: data)
    }
}

@objc public class Auto: NSObject {
    @objc public func getPluginVersion() -> String {
        return "native"
    }
}
