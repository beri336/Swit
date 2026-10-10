// Sources/Swit/Git/GitClient.swift

import Foundation

struct GitClient {
    let repoPath: String
    let gitExecutable: String

    private static let maxFileBytes = 80 * 1024

    static func open(at path: String) throws -> GitClient {
        guard let git = ExecutableFinder.find("git") else {
            throw SwitError.gitNotFound
        }

        let standardized = Self.resolvePath(path)
        let probe = GitClient(repoPath: standardized, gitExecutable: git)
        let inside: String

        do {
            inside = try probe.run(["rev-parse", "--is-inside-work-tree"])
        } catch {
            throw SwitError.notAGitRepo(standardized)
        }

        guard inside.trimmingCharacters(in: .whitespacesAndNewlines) == "true" else {
            throw SwitError.notAGitRepo(standardized)
        }

        let toplevel = try probe.run(["rev-parse", "--show-toplevel"])
                                        .trimmingCharacters(in: .whitespacesAndNewlines)

        return GitClient(repoPath: toplevel, gitExecutable: git)
    }

    func status() throws -> GitStatus {
        let output = try run(["status", "--porcelain=v1", "-uall", "--untracked-files=all"])
        return GitStatus.parsePorcelain(output)
    }

    func hasHead() -> Bool {
        (try? run(["rev-parse", "--verify", "HEAD"])) != nil
    }

    func previewDiff(mode: StagingMode) throws -> String {
        switch mode {
        case .stagedOnly:
            return try cachedDiff()
        case .tracked:
            return try trackedDiff()
        case .all:
            let tracked = try trackedDiff()
            let untracked = try untrackedPreview()
            return [tracked, untracked].filter {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }.joined(separator: "\n")
        }
    }

    func validateMode(_ mode: StagingMode, status: GitStatus) throws {
        switch mode {
            case .stagedOnly:
                if status.staged.isEmpty { throw SwitError.nothingStaged }
            case .tracked:
                if status.staged.isEmpty && status.unstaged.isEmpty { throw SwitError.noTrackedChanges }
            case .all:
                if status.isEmpty { throw SwitError.noChanges }
        }
    }

    func stage(mode: StagingMode) throws {
        switch mode {
            case .stagedOnly:
                return
            case .tracked:
                try runDiscardingOutput(["add", "-u", "--"])
            case .all:
                try runDiscardingOutput(["add", "-A", "--"])
        }
    }

    func commit(message: String) throws -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("swit-commit-\(UUID().uuidString).txt")

        try message.write(to: temp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: temp) }
        _ = try run(["commit", "-F", temp.path])

        return try run(["rev-parse", "--short", "HEAD"])
                      .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func cachedDiff() throws -> String {
        truncateDiff(try run(["diff", "--cached", "--"]))
    }

    private func trackedDiff() throws -> String {
        if hasHead() {
            return truncateDiff(try run(["diff", "HEAD", "--"]))
        }

        let cached = try run(["diff", "--cached", "--"])
        let unstaged = try run(["diff", "--"])

        return truncateDiff(cached + unstaged)
    }

    private func untrackedPreview() throws -> String {
        let listed = try run(["ls-files", "--others", "--exclude-standard"])
        let files = listed.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !files.isEmpty else { return "" }

        var chunks: [String] = []
        for file in files {
            chunks.append(try renderUntrackedFile(file))
        }

        return chunks.joined(separator: "\n")
    }

    private func renderUntrackedFile(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: relativePath,
                           relativeTo: URL(fileURLWithPath: repoPath, isDirectory: true))
                       .standardizedFileURL

        guard let data = try? Data(contentsOf: url) else {
            return "=== NEW FILE: \(relativePath) (unreadable) ===\n"
        }

        if data.contains(0) {
            return "=== NEW FILE: \(relativePath) [binary, omitted] ===\n"
        }

        var text = String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
        var truncated = false
        if data.count > Self.maxFileBytes {
            let prefix = data.prefix(Self.maxFileBytes)
            text = String(decoding: prefix, as: UTF8.self)
            truncated = true
        }

        var output = "=== NEW FILE: \(relativePath) ===\n"
        output += text
        if !text.hasSuffix("\n") {
            output += "\n"
        }

        if truncated {
            output += "… [truncated after \(Self.maxFileBytes) bytes]\n"
        }

        return output
    }

    private func truncateDiff(_ diff: String) -> String {
        let data = Data(diff.utf8)

        if data.count <= Self.maxFileBytes * 4 {
            return diff
        }

        let prefix = data.prefix(Self.maxFileBytes * 4)
        var text = String(decoding: prefix, as: UTF8.self)
        text += "\n… [diff truncated after \(Self.maxFileBytes * 4) bytes]\n"

        return text
    }

    @discardableResult
    func run(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: gitExecutable)
        process.arguments = ["--no-pager"] + arguments
        process.currentDirectoryURL = URL(fileURLWithPath: repoPath)
        process.environment = gitEnvironment()

        let fileManager = FileManager.default
        let outURL = fileManager.temporaryDirectory.appendingPathComponent("swit-out-\(UUID().uuidString)")
        let errURL = fileManager.temporaryDirectory.appendingPathComponent("swit-err-\(UUID().uuidString)")

        fileManager.createFile(atPath: outURL.path, contents: nil)
        fileManager.createFile(atPath: errURL.path, contents: nil)
        defer {
            try? fileManager.removeItem(at: outURL)
            try? fileManager.removeItem(at: errURL)
        }

        guard
            let stdout = try? FileHandle(forWritingTo: outURL),
            let stderr = try? FileHandle(forWritingTo: errURL)
        else {
            throw SwitError.gitFailed(command: arguments.joined(separator: " "),
                                      message: "temporary output files could not be opened")
        }

        process.standardOutput = stdout
        process.standardError = stderr
        process.standardInput = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            try? stdout.close()
            try? stderr.close()
            throw SwitError.gitFailed(command: arguments.joined(separator: " "),
                                      message: error.localizedDescription)
        }

        process.waitUntilExit()
        try? stdout.close()
        try? stderr.close()

        let out = (try? String(contentsOf: outURL, encoding: .utf8)) ?? ""
        let err = ((try? String(contentsOf: errURL, encoding: .utf8)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if process.terminationStatus != 0 {
            throw SwitError.gitFailed(command: arguments.joined(separator: " "), message: err)
        }

        return out.replacingOccurrences(of: "\r\n", with: "\n")
                  .replacingOccurrences(of: "\r", with: "\n")
    }

    private static func resolvePath(_ path: String) -> String {
        if path == "~" {
            return FileManager.default.homeDirectoryForCurrentUser.path
        }

        if path.hasPrefix("~/") || path.hasPrefix("~\\") {
            let rest = String(path.dropFirst(2))
            return URL(fileURLWithPath: rest, relativeTo: FileManager.default.homeDirectoryForCurrentUser)
                .standardizedFileURL.path
        }

        return URL(fileURLWithPath: path).standardizedFileURL.path
    }

    private func runDiscardingOutput(_ arguments: [String]) throws {
        _ = try run(arguments)
    }

    private func gitEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_OPTIONAL_LOCKS"] = "0"
        env["GIT_PAGER"] = "cat"

        return env
    }
}
