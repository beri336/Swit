// Tests/SwitTests/AppConfigurationTests.swift

import XCTest

@testable import Swit

final class AppConfigurationTests: XCTestCase {
    func testDefaultUsesExpectedValues() {
        XCTAssertEqual(AppConfiguration.default.model, "qwen2.5-coder:7b")
        XCTAssertEqual(AppConfiguration.default.host, "http://127.0.0.1:11434")
        XCTAssertEqual(AppConfiguration.default.temperature, 0.2)
    }

    func testConfigurationRoundTripsThroughJSON() throws {
        let configuration = AppConfiguration(
            model: "qwen2.5-coder:14b",
            host: "http://localhost:11434",
            temperature: 0.4
        )

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(AppConfiguration.self, from: data)

        XCTAssertEqual(decoded, configuration)
    }
}
