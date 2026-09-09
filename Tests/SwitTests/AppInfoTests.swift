// Tests/SwitTests/AppInfoTests.swift

import XCTest

@testable import Swit

final class AppInfoTests: XCTestCase {
    func testVersionUsesSemanticVersioningFormat() {
        let pattern = #"^\d+\.\d+\.\d+$"#

        XCTAssertNotNil(
            AppInfo.version.range(
                of: pattern,
                options: .regularExpression
            )
        )
    }

    func testCommandNameIsLowercase() {
        XCTAssertEqual(AppInfo.name, AppInfo.name.lowercased())
    }
}
