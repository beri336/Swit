// Tests/SwitTests/GitStatusTests.swift

import XCTest

@testable import Swit


/// Tests for GitStatus
final class GitStatusTests: XCTestCase {
    func testParsePorcelainReturnsEmptyStatusForEmptyOutput() {
        let status = GitStatus.parsePorcelain("")

        XCTAssertTrue(status.isEmpty)
        XCTAssertEqual(status.staged, [])
        XCTAssertEqual(status.unstaged, [])
        XCTAssertEqual(status.untracked, [])
    }

    func testParsePorcelainDetectsStagedFile() {
        let status = GitStatus.parsePorcelain("A  Sources/Swit/NewFile.swift\n")

        XCTAssertEqual(status.staged, ["Sources/Swit/NewFile.swift"])
        XCTAssertEqual(status.unstaged, [])
        XCTAssertEqual(status.untracked, [])
    }

    func testParsePorcelainDetectsUnstagedFile() {
        let status = GitStatus.parsePorcelain(" M README.md\n")

        XCTAssertEqual(status.staged, [])
        XCTAssertEqual(status.unstaged, ["README.md"])
        XCTAssertEqual(status.untracked, [])
    }

    func testParsePorcelainDetectsStagedAndUnstagedChanges() {
        let status = GitStatus.parsePorcelain("MM Sources/Swit/Git/GitClient.swift\n")

        XCTAssertEqual(status.staged, ["Sources/Swit/Git/GitClient.swift"])
        XCTAssertEqual(status.unstaged, ["Sources/Swit/Git/GitClient.swift"])
        XCTAssertEqual(status.untracked, [])
    }

    func testParsePorcelainDetectsUntrackedFile() {
        let status = GitStatus.parsePorcelain("?? Tests/SwitTests/GitStatusTests.swift\n")

        XCTAssertEqual(status.staged, [])
        XCTAssertEqual(status.unstaged, [])
        XCTAssertEqual(status.untracked, ["Tests/SwitTests/GitStatusTests.swift"])
    }

    func testParsePorcelainDetectsMultipleFileStates() {
        let output = """
            M  Package.swift
             M README.md
            MM Sources/Swit/Git/GitClient.swift
            ?? Tests/SwitTests/CommitMessageTests.swift
            """

        let status = GitStatus.parsePorcelain(output)

        XCTAssertEqual(
            status.staged,
            [
                "Package.swift",
                "Sources/Swit/Git/GitClient.swift",
            ]
        )
        XCTAssertEqual(
            status.unstaged,
            [
                "README.md",
                "Sources/Swit/Git/GitClient.swift",
            ]
        )
        XCTAssertEqual(
            status.untracked,
            [
                "Tests/SwitTests/CommitMessageTests.swift"
            ]
        )
    }

    func testParsePorcelainIgnoresIgnoredFiles() {
        let status = GitStatus.parsePorcelain("!! .build/\n")

        XCTAssertTrue(status.isEmpty)
    }

    func testParsePorcelainUsesNewPathForRename() {
        let status = GitStatus.parsePorcelain(
            "R  Sources/Swit/Swit.swift -> Sources/Swit/Swit.swift\n"
        )

        XCTAssertEqual(status.staged, ["Sources/Swit/Swit.swift"])
        XCTAssertEqual(status.unstaged, [])
        XCTAssertEqual(status.untracked, [])
    }
}
