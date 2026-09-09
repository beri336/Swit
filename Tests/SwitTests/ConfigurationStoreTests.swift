// Tests/SwitTests/ConfigurationStoreTests.swift

import Foundation
import XCTest

@testable import Swit

final class ConfigurationStoreTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
    }

    func testLoadReturnsDefaultsWhenFileDoesNotExist() throws {
        let store = makeStore()

        let configuration = try store.load()

        XCTAssertEqual(configuration, .default)
    }

    func testSaveCreatesConfigurationFile() throws {
        let store = makeStore()
        let configuration = AppConfiguration(
            model: "qwen2.5-coder:14b",
            host: "http://localhost:11434",
            temperature: 0.4
        )

        try store.save(configuration)

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    func testLoadReturnsSavedConfiguration() throws {
        let store = makeStore()
        let expected = AppConfiguration(
            model: "llama3.2:3b",
            host: "http://localhost:11434",
            temperature: 0.1
        )

        try store.save(expected)

        let actual = try store.load()

        XCTAssertEqual(actual, expected)
    }

    func testLoadThrowsForInvalidJSON() throws {
        let store = makeStore()
        try FileManager.default.createDirectory(
            at: store.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("{ invalid json".utf8).write(to: store.fileURL)

        XCTAssertThrowsError(try store.load()) { error in
            XCTAssertEqual(
                error as? SwitError,
                .invalidConfiguration(store.fileURL.path)
            )
        }
    }

    private func makeStore() -> ConfigurationStore {
        ConfigurationStore(
            fileURL: temporaryDirectory.appendingPathComponent("config.json")
        )
    }
}
