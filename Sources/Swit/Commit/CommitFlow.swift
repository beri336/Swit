// Sources/Gith/Commit/CommitFlow.swift

import Foundation

struct CommitFlow {
    let git: GitClient
    let ollama: OllamaClient
    let stagingMode: StagingMode?
    let dryRun: Bool

    private let prompts = Prompts()

    func run() async throws {
        let status = try git.status()
        prompts.printLine("Repo: \(git.repoPath)")
        prompts.printLine(
            "  staged: \(status.staged.count)  unstaged: \(status.unstaged.count)  untracked: \(status.untracked.count)"
        )
        printStatusFiles(status)

        if status.isEmpty {
            throw GithError.noChanges
        }

        let mode = try resolveStagingMode()
        try git.validateMode(mode, status: status)

        let diff = try git.previewDiff(mode: mode)
        if diff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw GithError.emptyDiff
        }

        prompts.printLine("Ask Ollama for a conventional commit suggestion …")
        var message = try await suggestMessage(diff: diff)

        if dryRun {
            printSuggestion(message)
            prompts.printLine("Dry-run: no git add / git commit.")
            return
        }

        while true {
            printSuggestion(message)
            switch try prompts.askReview() {
            case .abort:
                throw GithError.aborted
            case .edit:
                message = try prompts.editMessage(message)
            case .commit:
                let final = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if final.isEmpty {
                    throw GithError.emptyMessage
                }
                try git.stage(mode: mode)
                let hash = try git.commit(message: final)
                prompts.printLine("Commit \(hash) created.")
                return
            }
        }
    }

    private func resolveStagingMode() throws -> StagingMode {
        if let stagingMode {
            return stagingMode
        }

        return try prompts.askStagingMode()
    }

    private func suggestMessage(diff: String) async throws -> String {
        let raw = try await ollama.chat(system: CommitPrompt.system, user: CommitPrompt.user(diff: diff))
        var message = CommitMessage.normalize(raw)
        if CommitMessage.isValid(message) {
            return message
        }

        prompts.printLine("The suggestion doesn't fit the pattern; second attempt …")
        let retryRaw = try await ollama.chat(system: CommitPrompt.system, user: CommitPrompt.retry(previous: message))
        message = CommitMessage.normalize(retryRaw)
        if !CommitMessage.isValid(message) {
            prompts.printLine("Warning: The message does not follow the conventions for commits. You can still edit it.")
        }
        return message
    }

    private func printSuggestion(_ message: String) {
        prompts.printLine("Suggestion:")
        for line in message.split(separator: "\n", omittingEmptySubsequences: false) {
            prompts.printLine("  \(line)")
        }
        prompts.printLine("")
    }

    private func printStatusFiles(_ status: GitStatus) {
        let limit = 12
        func list(_ title: String, _ files: [String]) {
            guard !files.isEmpty else { return }
            let shown = files.prefix(limit)
            for file in shown {
                prompts.printLine("    \(title) \(file)")
            }
            if files.count > limit {
                prompts.printLine("    \(title) … +\(files.count - limit) weitere")
            }
        }
        list("S", status.staged)
        list("M", status.unstaged)
        list("?", status.untracked)
    }
}
