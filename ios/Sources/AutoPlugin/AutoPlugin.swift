import Foundation
import Capacitor

@objc(AutoPlugin)
public class AutoPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AutoPlugin"
    public let jsName = "Auto"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setRootTemplate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setTransientState", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getTransientState", returnType: CAPPluginReturnPromise),
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

        var rawTemplate: [String: Any] = [
            "title": title,
            "sections": call.getArray("sections") ?? []
        ]
        if let emptyText = call.getString("emptyText") {
            rawTemplate["emptyText"] = emptyText
        }

        guard let template = AutoTemplate.fromDictionary(rawTemplate) else {
            call.reject("title is required")
            return
        }

        AutoBridge.shared.setTemplate(template)
        call.resolve()
    }

    @objc func setState(_ call: CAPPluginCall) {
        guard let key = getStateKey(call) else { return }

        guard let value = call.getObject("value") else {
            call.reject("value is required for key=\(key)")
            return
        }

        AutoBridge.shared.setState(key: key, value: value)
        call.resolve()
    }

    @objc func getState(_ call: CAPPluginCall) {
        guard let key = getStateKey(call) else { return }

        call.resolve(stateResult(key: key, value: AutoBridge.shared.getState(key: key)))
    }

    @objc func removeState(_ call: CAPPluginCall) {
        guard let key = getStateKey(call) else { return }

        AutoBridge.shared.removeState(key: key)
        call.resolve()
    }

    @objc func setTransientState(_ call: CAPPluginCall) {
        guard let key = getStateKey(call) else { return }

        guard let value = call.getObject("value") else {
            call.reject("value is required for key=\(key)")
            return
        }

        AutoBridge.shared.setTransientState(key: key, value: value)
        call.resolve()
    }

    @objc func getTransientState(_ call: CAPPluginCall) {
        guard let key = getStateKey(call) else { return }

        call.resolve(stateResult(key: key, value: AutoBridge.shared.getTransientState(key: key)))
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

    private func getStateKey(_ call: CAPPluginCall) -> String? {
        guard let key = call.getString("key"), !key.isEmpty else {
            call.reject("key is required")
            return nil
        }

        guard key != AutoBridge.rootTemplateStateKey else {
            call.reject("key is reserved: \(AutoBridge.rootTemplateStateKey)")
            return nil
        }

        return key
    }

    private func stateResult(key: String, value: [String: Any]?) -> [String: Any] {
        var result: [String: Any] = ["key": key]
        if let value = value {
            result["value"] = value
        }
        return result
    }
}
