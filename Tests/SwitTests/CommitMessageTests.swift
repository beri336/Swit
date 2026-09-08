// Tests/SwitTests/CommitMessageTests.swift

import XCTest

@testable import Swit

/// Tests for CommitMessage
final class CommitMessageTests: XCTestCase {
    /// Removes leading/trailing whitespaces
    func testNormalizeTrimsWhitespace() {
        let raw = "  feat(cli): add dry run mode  \n"
        let msg = CommitMessage.normalize(raw)

        XCTAssertEqual(msg, "feat(cli): add dry run mode")
    }

    /// Removes markdown code fence
    func testNormalizeRemovesMarkdownCodeFence() {
        let raw = """
            ```text
            feat(commit): generate commit messages
            ```
            """
        let msg = CommitMessage.normalize(raw)

        XCTAssertEqual(msg, "feat(commit): generate commit messages")
    }

    /// Multiple lines are preserved
    func testNormalizeKeepsMultilineMessage() {
        let raw = """
            feat(commit): generate commit messages

            Use Ollama to propose conventional commits.
            """

        let message = CommitMessage.normalize(raw)

        XCTAssertEqual(
            message,
            """
            feat(commit): generate commit messages

            Use Ollama to propose conventional commits.
            """
        )
    }

    /// Validates commit message format
    func testIsValidAcceptsTypeWithoutScope() {
        let message = "chore: initialize swit project"

        XCTAssertTrue(CommitMessage.isValid(message))
    }

    func testIsValidAcceptsTypeWithScope() {
        let message = "feat(commit): generate commit messages"

        XCTAssertTrue(CommitMessage.isValid(message))
    }

    func testIsValidAcceptsAllowedScopeCharacters() {
        let message = "fix(git/status_v2): parse renamed files"

        XCTAssertTrue(CommitMessage.isValid(message))
    }

    func testIsValidUsesOnlyFirstLineForValidation() {
        let message = """
            feat(commit): generate commit messages

            Add Ollama-powered suggestions for changed files.
            """

        XCTAssertTrue(CommitMessage.isValid(message))
    }

    func testIsValidRejectsUnknownType() {
        let message = "initial: add project files"

        XCTAssertFalse(CommitMessage.isValid(message))
    }

    func testIsValidRejectsMissingColon() {
        let message = "feat(commit) generate commit messages"

        XCTAssertFalse(CommitMessage.isValid(message))
    }

    func testIsValidRejectsEmptySubject() {
        let message = "feat(commit): "

        XCTAssertFalse(CommitMessage.isValid(message))
    }

    func testIsValidRejectsScopeWithWhitespace() {
        let message = "feat(commit flow): generate commit messages"

        XCTAssertFalse(CommitMessage.isValid(message))
    }
}
