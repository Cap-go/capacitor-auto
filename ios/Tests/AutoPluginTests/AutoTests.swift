import XCTest
@testable import AutoPlugin

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
        AutoStore.shared.save(key, ["route": ["id": "main"]])

        let storedRoute = AutoStore.shared.load(key)?["route"] as? [String: Any]
        XCTAssertEqual("main", storedRoute?["id"] as? String)

        AutoStore.shared.remove(key)
        XCTAssertNil(AutoStore.shared.load(key))
    }
}
