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
}
