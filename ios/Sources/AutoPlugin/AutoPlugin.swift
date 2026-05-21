import Foundation
import Capacitor

@objc(AutoPlugin)
public class AutoPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AutoPlugin"
    public let jsName = "Auto"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setRootTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sendMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPluginVersion", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = Auto()

    override public func load() {
        AutoBridge.shared.attach(self)
    }

    deinit {
        AutoBridge.shared.detach(self)
    }

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve([
            "available": true,
            "connected": AutoBridge.shared.connected,
            "platform": "ios"
        ])
    }

    @objc func setRootTemplate(_ call: CAPPluginCall) {
        guard let title = call.getString("title"), !title.isEmpty else {
            call.reject("title is required")
            return
        }

        let sections = parseSections(call.getArray("sections") ?? [])
        AutoBridge.shared.setTemplate(AutoTemplate(
            title: title,
            sections: sections,
            emptyText: call.getString("emptyText") ?? "No actions available."
        ))
        call.resolve()
    }

    @objc func sendMessage(_ call: CAPPluginCall) {
        guard let type = call.getString("type"), !type.isEmpty else {
            call.reject("type is required")
            return
        }

        AutoBridge.shared.receiveMessage(type: type, payload: call.getObject("payload"))
        call.resolve()
    }

    @objc func getPluginVersion(_ call: CAPPluginCall) {
        call.resolve([
            "version": implementation.getPluginVersion()
        ])
    }

    func emitEvent(_ eventName: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.notifyListeners(eventName, data: data, retainUntilConsumed: true)
        }
    }

    private func parseSections(_ rawSections: [Any]) -> [AutoTemplateSection] {
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

    private func parseItem(_ rawItem: [String: Any]) -> AutoTemplateItem? {
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
