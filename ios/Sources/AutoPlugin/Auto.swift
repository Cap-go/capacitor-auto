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
}

extension Notification.Name {
    static let capgoAutoTemplateChanged = Notification.Name("CapgoAutoTemplateChanged")
}

public final class AutoBridge {
    public static let shared = AutoBridge()

    private weak var plugin: AutoPlugin?
    private var pendingEvents: [(String, [String: Any])] = []

    public private(set) var template = AutoTemplate.fallback
    public private(set) var connected = false
    public private(set) var lastMessage: [String: Any]?

    private init() {}

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
        NotificationCenter.default.post(name: .capgoAutoTemplateChanged, object: nil)
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
}

@objc public class Auto: NSObject {
    @objc public func getPluginVersion() -> String {
        return "native"
    }
}
