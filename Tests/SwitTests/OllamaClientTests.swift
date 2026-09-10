// Tests/SwitTests/OllamaClientTests.swift

import XCTest

@testable import Swit

final class OllamaClientTests: XCTestCase {
    func testInitAcceptsHTTPHost() throws {
        let client = try OllamaClient(
            host: "http://127.0.0.1:11434",
            model: "qwen2.5-coder:7b"
        )

        XCTAssertEqual(client.host.absoluteString, "http://127.0.0.1:11434")
    }

    func testInitAcceptsHTTPSHost() throws {
        let client = try OllamaClient(
            host: "https://ollama.example.com",
            model: "qwen2.5-coder:7b"
        )

        XCTAssertEqual(client.host.absoluteString, "https://ollama.example.com")
    }

    func testInitRejectsHostWithoutScheme() {
        XCTAssertThrowsError(
            try OllamaClient(
                host: "localhost:11434",
                model: "qwen2.5-coder:7b"
            )
        ) { error in
            XCTAssertEqual(
                error as? SwitError,
                .invalidHost("localhost:11434")
            )
        }
    }

    func testInitRejectsUnsupportedScheme() {
        XCTAssertThrowsError(
            try OllamaClient(
                host: "ftp://127.0.0.1:11434",
                model: "qwen2.5-coder:7b"
            )
        ) { error in
            XCTAssertEqual(
                error as? SwitError,
                .invalidHost("ftp://127.0.0.1:11434")
            )
        }
    }

    func testInitRejectsHostWithoutHostname() {
        XCTAssertThrowsError(
            try OllamaClient(
                host: "http://",
                model: "qwen2.5-coder:7b"
            )
        ) { error in
            XCTAssertEqual(
                error as? SwitError,
                .invalidHost("http://")
            )
        }
    }

    func testInitUsesDefaultGenerationSettings() throws {
        let client = try OllamaClient(
            host: "http://127.0.0.1:11434",
            model: "qwen2.5-coder:7b"
        )

        XCTAssertEqual(client.temperature, AppConfiguration.defaultTemperature)
        XCTAssertEqual(client.contextWindow, AppConfiguration.defaultContextWindow)
        XCTAssertEqual(client.keepAlive, AppConfiguration.defaultKeepAlive)
    }

    func testInitUsesProvidedGenerationSettings() throws {
        let client = try OllamaClient(
            host: "http://127.0.0.1:11434",
            model: "qwen2.5-coder:7b",
            temperature: 0.7,
            contextWindow: 16_384,
            keepAlive: "15m"
        )

        XCTAssertEqual(client.temperature, 0.7)
        XCTAssertEqual(client.contextWindow, 16_384)
        XCTAssertEqual(client.keepAlive, "15m")
    }
    func testInitRejectsInvalidGenerationSettings() {
        XCTAssertThrowsError(
            try OllamaClient(
                host: "http://127.0.0.1:11434",
                model: "qwen2.5-coder:7b",
                temperature: 2.1
            )
        ) { error in
            XCTAssertEqual(error as? SwitError, .invalidTemperature(2.1))
        }

        XCTAssertThrowsError(
            try OllamaClient(
                host: "http://127.0.0.1:11434",
                model: "qwen2.5-coder:7b",
                contextWindow: 0
            )
        ) { error in
            XCTAssertEqual(error as? SwitError, .invalidContextWindow(0))
        }

        XCTAssertThrowsError(
            try OllamaClient(
                host: "http://127.0.0.1:11434",
                model: "qwen2.5-coder:7b",
                keepAlive: "forever"
            )
        ) { error in
            XCTAssertEqual(error as? SwitError, .invalidKeepAlive("forever"))
        }
    }
}
