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
}
