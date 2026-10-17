// Tests/SwitTests/GitClientTests.swift

import Foundation
import XCTest

@testable import Swit

final class GitClientTests: XCTestCase {
    func testRepositorySnapshotRemainsEqualWithoutChanges() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            for mode in [
                StagingMode.stagedOnly,
                .tracked,
                .all,
            ] {
                let first = try git.repositorySnapshot(mode: mode)
                let second = try git.repositorySnapshot(mode: mode)

                XCTAssertEqual(first, second)
            }
        }
    }

    func testTrackedFileChangeChangesSelectedTree() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            let trackedBefore = try git.repositorySnapshot(mode: .tracked)
            let allBefore = try git.repositorySnapshot(mode: .all)

            try write(
                "Updated content\n",
                to: "tracked.txt",
                in: directory
            )

            let trackedAfter = try git.repositorySnapshot(mode: .tracked)
            let allAfter = try git.repositorySnapshot(mode: .all)

            XCTAssertNotEqual(
                trackedBefore.selectedTree,
                trackedAfter.selectedTree
            )
            XCTAssertNotEqual(
                allBefore.selectedTree,
                allAfter.selectedTree
            )

            XCTAssertEqual(
                trackedBefore.indexTree,
                trackedAfter.indexTree
            )
        }
    }

    func testStagedOnlySnapshotIgnoresUnstagedContentChanges() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            try write(
                "Staged content\n",
                to: "tracked.txt",
                in: directory
            )
            try git.run(["add", "--", "tracked.txt"])

            let before = try git.repositorySnapshot(mode: .stagedOnly)

            try write(
                "Additional unstaged content\n",
                to: "tracked.txt",
                in: directory
            )

            let after = try git.repositorySnapshot(mode: .stagedOnly)

            XCTAssertEqual(before, after)
        }
    }

    func testUntrackedFileChangesAllSnapshotButNotTrackedSnapshot() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            let trackedBefore = try git.repositorySnapshot(mode: .tracked)
            let allBefore = try git.repositorySnapshot(mode: .all)

            try write(
                "New file\n",
                to: "untracked.txt",
                in: directory
            )

            let trackedAfter = try git.repositorySnapshot(mode: .tracked)
            let allAfter = try git.repositorySnapshot(mode: .all)

            XCTAssertEqual(trackedBefore, trackedAfter)
            XCTAssertNotEqual(
                allBefore.selectedTree,
                allAfter.selectedTree
            )
            XCTAssertEqual(
                allBefore.indexTree,
                allAfter.indexTree
            )
        }
    }

    func testStagingFileChangesIndexTree() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            try write(
                "Updated content\n",
                to: "tracked.txt",
                in: directory
            )

            let before = try git.repositorySnapshot(mode: .tracked)

            try git.run(["add", "--", "tracked.txt"])

            let after = try git.repositorySnapshot(mode: .tracked)

            XCTAssertNotEqual(before, after)
            XCTAssertNotEqual(before.indexTree, after.indexTree)

            XCTAssertEqual(
                before.selectedTree,
                after.selectedTree
            )
        }
    }

    func testRepositorySnapshotsDoNotModifyRealIndexOrWorkingTree() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            try write(
                "Staged content\n",
                to: "tracked.txt",
                in: directory
            )
            try git.run(["add", "--", "tracked.txt"])

            try write(
                "Unstaged content\n",
                to: "tracked.txt",
                in: directory
            )
            try write(
                "Untracked content\n",
                to: "untracked.txt",
                in: directory
            )

            let indexURL = directory.appendingPathComponent(".git/index")
            let indexBefore = try Data(contentsOf: indexURL)
            let statusBefore = try git.run([
                "status",
                "--porcelain=v1",
                "-uall",
            ])
            let cachedDiffBefore = try git.run([
                "diff",
                "--cached",
                "--",
            ])
            let trackedFileBefore = try Data(
                contentsOf: directory.appendingPathComponent("tracked.txt")
            )
            let untrackedFileBefore = try Data(
                contentsOf: directory.appendingPathComponent("untracked.txt")
            )

            for mode in [
                StagingMode.stagedOnly,
                .tracked,
                .all,
            ] {
                _ = try git.repositorySnapshot(mode: mode)
            }

            let indexAfter = try Data(contentsOf: indexURL)
            let statusAfter = try git.run([
                "status",
                "--porcelain=v1",
                "-uall",
            ])
            let cachedDiffAfter = try git.run([
                "diff",
                "--cached",
                "--",
            ])
            let trackedFileAfter = try Data(
                contentsOf: directory.appendingPathComponent("tracked.txt")
            )
            let untrackedFileAfter = try Data(
                contentsOf: directory.appendingPathComponent("untracked.txt")
            )

            XCTAssertEqual(indexBefore, indexAfter)
            XCTAssertEqual(statusBefore, statusAfter)
            XCTAssertEqual(cachedDiffBefore, cachedDiffAfter)
            XCTAssertEqual(trackedFileBefore, trackedFileAfter)
            XCTAssertEqual(untrackedFileBefore, untrackedFileAfter)
        }
    }

    func testRepositorySnapshotWorksWithoutInitialCommit() throws {
        try withRepository { git, directory in
            try write(
                "New file\n",
                to: "untracked.txt",
                in: directory
            )

            let staged = try git.repositorySnapshot(mode: .stagedOnly)
            let all = try git.repositorySnapshot(mode: .all)

            XCTAssertNil(staged.head)
            XCTAssertNil(all.head)

            XCTAssertEqual(staged.indexTree, staged.selectedTree)
            XCTAssertEqual(staged.indexTree, all.indexTree)
            XCTAssertNotEqual(all.indexTree, all.selectedTree)

            try git.stage(mode: .all)

            let stagedAfter = try git.repositorySnapshot(mode: .stagedOnly)

            XCTAssertNil(stagedAfter.head)
            XCTAssertEqual(all.selectedTree, stagedAfter.indexTree)
        }
    }

    func testActualStagingMatchesPredictedSelectedTree() throws {
        for mode in [
            StagingMode.stagedOnly,
            .tracked,
            .all,
        ] {
            try withRepository { git, directory in
                try createInitialCommit(git: git, directory: directory)

                try write(
                    "Staged content\n",
                    to: "tracked.txt",
                    in: directory
                )
                try git.run(["add", "--", "tracked.txt"])

                try write(
                    "Additional unstaged content\n",
                    to: "tracked.txt",
                    in: directory
                )
                try write(
                    "New file\n",
                    to: "untracked.txt",
                    in: directory
                )

                let expected = try git.repositorySnapshot(mode: mode)

                try git.stage(mode: mode)

                let actual = try git.repositorySnapshot(mode: .stagedOnly)

                XCTAssertEqual(expected.head, actual.head)
                XCTAssertEqual(
                    expected.selectedTree,
                    actual.indexTree,
                    "Actual staging must match the predicted tree."
                )
            }
        }
    }

    func testTrackedFileDeletionChangesSelectedTree() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            let before = try git.repositorySnapshot(mode: .tracked)

            try FileManager.default.removeItem(
                at: directory.appendingPathComponent("tracked.txt")
            )

            let after = try git.repositorySnapshot(mode: .tracked)

            XCTAssertNotEqual(
                before.selectedTree,
                after.selectedTree
            )
            XCTAssertEqual(before.indexTree, after.indexTree)
        }
    }

    func testBinaryContentChangeChangesSelectedTree() throws {
        try withRepository { git, directory in
            try createInitialCommit(git: git, directory: directory)

            let binaryURL = directory.appendingPathComponent("binary.dat")

            try Data([0, 1, 2, 3]).write(to: binaryURL)
            try git.run(["add", "--", "binary.dat"])
            try createCommit(git: git, message: "Add binary file")

            let before = try git.repositorySnapshot(mode: .tracked)

            try Data([0, 1, 2, 4]).write(to: binaryURL)

            let after = try git.repositorySnapshot(mode: .tracked)

            XCTAssertNotEqual(
                before.selectedTree,
                after.selectedTree
            )
            XCTAssertEqual(before.indexTree, after.indexTree)
        }
    }

    // MARK: - Helpers

    private func withRepository(
        _ body: (GitClient, URL) throws -> Void
    ) throws {
        guard let executable = ExecutableFinder.find("git") else {
            throw XCTSkip("Git is required for GitClient integration tests.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "swit-git-tests-\(UUID().uuidString)",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let git = GitClient(
            repoPath: directory.path,
            gitExecutable: executable
        )

        try git.run(["init", "--quiet"])

        try body(git, directory)
    }

    private func createInitialCommit(
        git: GitClient,
        directory: URL
    ) throws {
        try write(
            "Initial content\n",
            to: "tracked.txt",
            in: directory
        )

        try git.run(["add", "--", "tracked.txt"])
        try createCommit(git: git, message: "Initial commit")
    }

    private func createCommit(
        git: GitClient,
        message: String
    ) throws {
        try git.run(
            [
                "-c", "core.hooksPath=/dev/null",
                "-c", "commit.gpgsign=false",
                "commit",
                "--quiet",
                "-m", message,
            ],
            environmentOverrides: [
                "GIT_AUTHOR_NAME": "Swit Tests",
                "GIT_AUTHOR_EMAIL": "tests@example.invalid",
                "GIT_COMMITTER_NAME": "Swit Tests",
                "GIT_COMMITTER_EMAIL": "tests@example.invalid",
            ]
        )
    }

    private func write(
        _ content: String,
        to relativePath: String,
        in directory: URL
    ) throws {
        try content.write(
            to: directory.appendingPathComponent(relativePath),
            atomically: true,
            encoding: .utf8
        )
    }
}
