import Foundation

public protocol AutoStoreListener: AnyObject {
    func onAutoStoreUpdated(_ key: String, value: [String: Any]?, transient: Bool)
}

public final class AutoStore {
    public static let shared = AutoStore()

    private static let prefsPrefix = "capgo_auto_store."

    private final class WeakListener {
        weak var value: AutoStoreListener?

        init(_ value: AutoStoreListener) {
            self.value = value
        }
    }

    private let defaults = UserDefaults.standard
    private let lock = NSRecursiveLock()
    private var listeners: [WeakListener] = []
    private var transientValues: [String: [String: Any]] = [:]

    private init() {}

    public func addListener(_ listener: AutoStoreListener) {
        lock.lock()
        defer { lock.unlock() }

        listeners.removeAll { $0.value == nil || $0.value === listener }
        listeners.append(WeakListener(listener))
    }

    public func removeListener(_ listener: AutoStoreListener) {
        lock.lock()
        defer { lock.unlock() }

        listeners.removeAll { $0.value == nil || $0.value === listener }
    }

    public func save(_ key: String, _ value: [String: Any]) {
        guard
            let snapshot = Self.snapshot(value),
            let json = Self.jsonString(snapshot)
        else {
            return
        }

        defaults.set(json, forKey: Self.storageKey(key))
        notifyChanged(key, value: snapshot, transient: false)
    }

    public func remove(_ key: String) {
        defaults.removeObject(forKey: Self.storageKey(key))
        notifyChanged(key, value: nil, transient: false)
    }

    public func load(_ key: String) -> [String: Any]? {
        guard
            let raw = defaults.string(forKey: Self.storageKey(key)),
            let data = raw.data(using: .utf8),
            let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        return value
    }

    public func setTransient(_ key: String, _ value: [String: Any]?) {
        let snapshot = value.flatMap(Self.snapshot)

        lock.lock()
        let previous = transientValues[key]
        transientValues[key] = snapshot
        lock.unlock()

        if Self.jsonString(previous) != Self.jsonString(snapshot) {
            notifyChanged(key, value: snapshot, transient: true)
        }
    }

    public func getTransient(_ key: String) -> [String: Any]? {
        lock.lock()
        defer { lock.unlock() }

        return transientValues[key].flatMap(Self.snapshot)
    }

    private func notifyChanged(_ key: String, value: [String: Any]?, transient: Bool) {
        let eventValue = value.flatMap(Self.snapshot)

        DispatchQueue.main.async {
            self.lock.lock()
            let listenerSnapshot = self.listeners.compactMap { $0.value }
            self.listeners.removeAll { $0.value == nil }
            self.lock.unlock()

            for listener in listenerSnapshot {
                listener.onAutoStoreUpdated(key, value: eventValue.flatMap(Self.snapshot), transient: transient)
            }
        }
    }

    private static func storageKey(_ key: String) -> String {
        prefsPrefix + key
    }

    private static func jsonString(_ value: [String: Any]?) -> String? {
        guard
            let value,
            JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(withJSONObject: value)
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func snapshot(_ value: [String: Any]) -> [String: Any]? {
        guard
            JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(withJSONObject: value),
            let snapshot = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        return snapshot
    }
}
