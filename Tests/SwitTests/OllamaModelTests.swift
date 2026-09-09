// Tests/SwitTests/OllamaModelTests.swift

import Foundation
import XCTest

@testable import Swit

final class OllamaModelTests: XCTestCase {
    func testDecodesModelList() throws {
        let data = Data(
            """
            {
              "models": [
                { "name": "qwen2.5-coder:7b" },
                { "name": "llama3.2:3b" }
              ]
            }
            """.utf8
        )

        let modelList = try JSONDecoder().decode(OllamaModelList.self, from: data)

        XCTAssertEqual(
            modelList.models,
            [
                OllamaModel(name: "qwen2.5-coder:7b"),
                OllamaModel(name: "llama3.2:3b"),
            ]
        )
    }

    func testDecodesEmptyModelList() throws {
        let data = Data(#"{"models":[]}"#.utf8)

        let modelList = try JSONDecoder().decode(OllamaModelList.self, from: data)

        XCTAssertEqual(modelList.models, [])
    }
}
