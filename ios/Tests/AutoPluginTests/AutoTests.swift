import XCTest
@testable import AutoPlugin

private struct AutoStoreUpdate {
    let key: String
    let value: [String: Any]?
    let transient: Bool
}

private final class RecordingAutoStoreListener: AutoStoreListener {
    var updates: [AutoStoreUpdate] = []
    var expectation: XCTestExpectation?

    func onAutoStoreUpdated(_ key: String, value: [String: Any]?, transient: Bool) {
        updates.append(AutoStoreUpdate(key: key, value: value, transient: transient))
        expectation?.fulfill()
    }
}

class AutoTests: XCTestCase {
    func testGetPluginVersion() {
        let implementation = Auto()
        let result = implementation.getPluginVersion()

        XCTAssertEqual("native", result)
    }

    func testDefaultBridgeState() {
        XCTAssertFalse(AutoBridge.shared.connected)
        XCTAssertEqual("Auto", AutoBridge.shared.template.title)
    }

    func testTemplateRoundTripsThroughDictionary() {
        let template = AutoTemplate(
            title: "Drive",
            sections: [
                AutoTemplateSection(
                    header: "Routes",
                    items: [
                        AutoTemplateItem(
                            id: "start",
                            title: "Start route",
                            subtitle: "Main",
                            payload: ["routeId": "main"],
                            enabled: true
                        )
                    ]
                )
            ],
            emptyText: "No routes"
        )

        let restored = AutoTemplate.fromDictionary(template.toDictionary())

        XCTAssertEqual("Drive", restored?.title)
        XCTAssertEqual("Routes", restored?.sections.first?.header)
        XCTAssertEqual("start", restored?.sections.first?.items.first?.id)
        XCTAssertEqual("main", restored?.sections.first?.items.first?.payload?["routeId"] as? String)
    }

    func testAutoStoreSavesAndRemovesState() {
        let key = "test-\(UUID().uuidString)"
        let listener = RecordingAutoStoreListener()

        AutoStore.shared.remove(key)
        AutoStore.shared.setTransient(key, nil)

        AutoStore.shared.save(key, ["route": ["id": "main"]])

        let storedRoute = AutoStore.shared.load(key)?["route"] as? [String: Any]
        XCTAssertEqual("main", storedRoute?["id"] as? String)

        AutoStore.shared.addListener(listener)

        let transientExpectation = expectation(description: "transient update delivered")
        listener.expectation = transientExpectation
        AutoStore.shared.setTransient(key, ["route": ["id": "transient"]])
        wait(for: [transientExpectation], timeout: 1)

        let transientRoute = listener.updates.last?.value?["route"] as? [String: Any]
        XCTAssertEqual(key, listener.updates.last?.key)
        XCTAssertEqual("transient", transientRoute?["id"] as? String)
        XCTAssertEqual("transient", (AutoStore.shared.getTransient(key)?["route"] as? [String: Any])?["id"] as? String)
        XCTAssertEqual("main", (AutoStore.shared.load(key)?["route"] as? [String: Any])?["id"] as? String)
        XCTAssertEqual(true, listener.updates.last?.transient)

        let removeExpectation = expectation(description: "remove update delivered")
        listener.expectation = removeExpectation
        AutoStore.shared.remove(key)
        wait(for: [removeExpectation], timeout: 1)

        XCTAssertEqual(key, listener.updates.last?.key)
        XCTAssertNil(listener.updates.last?.value)
        XCTAssertEqual(false, listener.updates.last?.transient)
        XCTAssertNil(AutoStore.shared.load(key))

        AutoStore.shared.removeListener(listener)
        let updateCount = listener.updates.count
        let removedListenerExpectation = expectation(description: "removed listener not notified")
        removedListenerExpectation.isInverted = true
        listener.expectation = removedListenerExpectation

        AutoStore.shared.setTransient(key, ["route": ["id": "ignored"]])
        wait(for: [removedListenerExpectation], timeout: 0.2)

        XCTAssertEqual(updateCount, listener.updates.count)
        AutoStore.shared.setTransient(key, nil)
    }
}
