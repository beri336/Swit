// Tests/SwitTests/StagingModeTests.swift

import XCTest

@testable import Swit

/// Tests for StagingMode
final class StagingModeTests: XCTestCase {
    func testInitAcceptsStagedAliases() {
        XCTAssertEqual(StagingMode(argument: "staged"), .stagedOnly)
        XCTAssertEqual(StagingMode(argument: "staged-only"), .stagedOnly)
    }

    func testInitAcceptsTracked() {
        XCTAssertEqual(StagingMode(argument: "tracked"), .tracked)
    }

    func testInitAcceptsAll() {
        XCTAssertEqual(StagingMode(argument: "all"), .all)
    }

    func testInitIsCaseInsensitive() {
        XCTAssertEqual(StagingMode(argument: "TRACKED"), .tracked)
    }

    func testInitRejectsUnknownValue() {
        XCTAssertNil(StagingMode(argument: "everything"))
    }
}
