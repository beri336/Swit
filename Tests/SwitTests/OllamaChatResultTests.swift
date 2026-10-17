// Tests/SwitTests/OllamaChatResultTests.swift

import Foundation
import XCTest

@testable import Swit

final class OllamaChatResultTests: XCTestCase {
    func testDecodesContentAndUsageMetrics() throws {
        let result = try decode(
            """
            {
                "message": {
                    "role": "assistant",
                    "content": "feat(cli): add verbose output"
                },
                "total_duration": 4800000000,
                "load_duration": 500000000,
                "prompt_eval_count": 2310,
                "eval_count": 42,
                "eval_duration": 2000000000,
                "done_reason": "stop"
            }
            """
        )

        XCTAssertEqual(
            result.content,
            "feat(cli): add verbose output"
        )
        XCTAssertEqual(result.totalDuration, 4_800_000_000)
        XCTAssertEqual(result.loadDuration, 500_000_000)
        XCTAssertEqual(result.promptEvalCount, 2310)
        XCTAssertEqual(result.evalCount, 42)
        XCTAssertEqual(result.evalDuration, 2_000_000_000)
        XCTAssertEqual(result.doneReason, "stop")
    }

    func testConvertsNanosecondsToSeconds() throws {
        let result = try decode(
            """
            {
                "total_duration": 4800000000,
                "load_duration": 500000000,
                "eval_duration": 2000000000
            }
            """
        )

        XCTAssertEqual(
            try XCTUnwrap(result.totalDurationSeconds),
            4.8,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            try XCTUnwrap(result.loadDurationSeconds),
            0.5,
            accuracy: 0.000001
        )
        XCTAssertEqual(
            try XCTUnwrap(result.outputDurationSeconds),
            2.0,
            accuracy: 0.000001
        )
    }

    func testMissingMetricsRemainUnavailable() throws {
        let result = try decode(
            """
            {
                "message": {
                    "content": "fix(cli): handle missing metrics"
                }
            }
            """
        )

        XCTAssertEqual(
            result.content,
            "fix(cli): handle missing metrics"
        )
        XCTAssertNil(result.totalDurationSeconds)
        XCTAssertNil(result.loadDurationSeconds)
        XCTAssertNil(result.outputDurationSeconds)
        XCTAssertNil(result.promptEvalCount)
        XCTAssertNil(result.evalCount)
        XCTAssertNil(result.doneReason)
    }

    func testContentTrimsWhitespaceAndNewlines() throws {
        let result = try decode(
            """
            {
                "message": {
                    "content": "  feat(cli): add verbose output\\n"
                }
            }
            """
        )

        XCTAssertEqual(
            result.content,
            "feat(cli): add verbose output"
        )
    }

    func testMissingMessageProducesEmptyContent() throws {
        let result = try decode("{}")

        XCTAssertEqual(result.content, "")
    }

    func testZeroMetricsRemainZero() throws {
        let result = try decode(
            """
            {
                "total_duration": 0,
                "load_duration": 0,
                "prompt_eval_count": 0,
                "eval_count": 0,
                "eval_duration": 0
            }
            """
        )

        XCTAssertEqual(result.totalDurationSeconds, 0)
        XCTAssertEqual(result.loadDurationSeconds, 0)
        XCTAssertEqual(result.outputDurationSeconds, 0)
        XCTAssertEqual(result.promptEvalCount, 0)
        XCTAssertEqual(result.evalCount, 0)
    }

    func testNegativeDurationsAreUnavailable() throws {
        let result = try decode(
            """
            {
                "total_duration": -1,
                "load_duration": -1,
                "eval_duration": -1
            }
            """
        )

        XCTAssertNil(result.totalDurationSeconds)
        XCTAssertNil(result.loadDurationSeconds)
        XCTAssertNil(result.outputDurationSeconds)
    }

    private func decode(_ json: String) throws -> OllamaChatResult {
        try JSONDecoder().decode(
            OllamaChatResult.self,
            from: Data(json.utf8)
        )
    }
}
