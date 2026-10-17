// Tests/SwitTests/ConfigurationValidatorTests.swift

import XCTest

@testable import Swit

final class ConfigurationValidatorTests: XCTestCase {
    func testTemperatureAcceptsValuesWithinAllowedRange() {
        XCTAssertTrue(ConfigurationValidator.isValid(temperature: 0.0))
        XCTAssertTrue(ConfigurationValidator.isValid(temperature: 0.2))
        XCTAssertTrue(ConfigurationValidator.isValid(temperature: 2.0))
    }

    func testTemperatureRejectsValuesOutsideAllowedRange() {
        XCTAssertFalse(ConfigurationValidator.isValid(temperature: -0.1))
        XCTAssertFalse(ConfigurationValidator.isValid(temperature: 2.1))
        XCTAssertFalse(ConfigurationValidator.isValid(temperature: .infinity))
        XCTAssertFalse(ConfigurationValidator.isValid(temperature: .nan))
    }

    func testContextWindowAcceptsValuesWithinAllowedRange() {
        let validValues = [
            2_048,
            8_192,
            32_768,
        ]

        for value in validValues {
            XCTAssertTrue(
                ConfigurationValidator.isValid(contextWindow: value),
                "Expected \(value) to be a valid context window."
            )
        }
    }

    func testContextWindowRejectsValuesOutsideAllowedRange() {
        let invalidValues = [
            Int.min,
            -1,
            0,
            1,
            2_047,
            32_769,
            2_000_000,
            Int.max,
        ]

        for value in invalidValues {
            XCTAssertFalse(
                ConfigurationValidator.isValid(contextWindow: value),
                "Expected \(value) to be an invalid context window."
            )
        }
    }

    func testContextWindowRejectsZeroAndNegativeValues() {
        XCTAssertFalse(ConfigurationValidator.isValid(contextWindow: 0))
        XCTAssertFalse(ConfigurationValidator.isValid(contextWindow: -1))
    }

    func testKeepAliveAcceptsSpecialValues() {
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "0"))
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "-1"))
    }

    func testKeepAliveAcceptsDurations() {
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "30s"))
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "5m"))
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "2h"))
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: "1d"))
    }

    func testKeepAliveTrimsWhitespace() {
        XCTAssertTrue(ConfigurationValidator.isValid(keepAlive: " 15m\n"))
    }

    func testKeepAliveRejectsInvalidValues() {
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: ""))
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: "0m"))
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: "-5m"))
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: "2.5m"))
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: "forever"))
        XCTAssertFalse(ConfigurationValidator.isValid(keepAlive: "10w"))
    }
}
