// Tests/SwitTests/AppConfigurationTests.swift

import XCTest

@testable import Swit

final class AppConfigurationTests: XCTestCase {
    func testDecodesOlderConfigurationUsingNewDefaults() throws {
        let data = Data(
            """
            {
              "model": "qwen2.5-coder:14b",
              "host": "http://localhost:11434",
              "temperature": 0.4
            }
            """.utf8
        )

        let configuration = try JSONDecoder().decode(AppConfiguration.self, from: data)

        XCTAssertEqual(configuration.model, "qwen2.5-coder:14b")
        XCTAssertEqual(configuration.host, "http://localhost:11434")
        XCTAssertEqual(configuration.temperature, 0.4)
        XCTAssertEqual(configuration.contextWindow, AppConfiguration.defaultContextWindow)
        XCTAssertEqual(configuration.keepAlive, AppConfiguration.defaultKeepAlive)
    }
}
