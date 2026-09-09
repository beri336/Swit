// Sources/Gith/Commit/CommitFlow.swift

import Foundation

struct CommitFlow {
    let git: GitClient
    let ollama: OllamaClient
    let stagingMode: StagingMode?
    let dryRun: Bool

    private let prompts = Prompts()

    func run() async throws {
        prompts.printBanner()

        let status = try git.status()

        prompts.printLine(
            "\(TerminalStyle.yellow(TerminalStyle.bold("Repository: ")))"
                + "\(TerminalStyle.cyan(git.repoPath))"
        )
        prompts.printLine(
            "\(TerminalStyle.yellow(TerminalStyle.bold("Changes: ")))"
                + "\(TerminalStyle.green("staged \(status.staged.count)"))  "
                + "\(TerminalStyle.yellow("modified \(status.unstaged.count)"))  "
                + "\(TerminalStyle.dim("untracked \(status.untracked.count)"))"
        )

        printStatusFiles(status)

        if status.isEmpty {
            throw SwitError.noChanges
        }

        let mode = try resolveStagingMode()
        try git.validateMode(mode, status: status)

        let diff = try git.previewDiff(mode: mode)
        if diff.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw SwitError.emptyDiff
        }

        prompts.printLine(
            "\(TerminalStyle.yellow(TerminalStyle.bold("Ollama ")))"
                + "\(TerminalStyle.dim("creates a suggestion for a conventional commit …"))"
        )

        var message = try await suggestMessage(diff: diff)

        if dryRun {
            printSuggestion(message)
            prompts.printLine(
                "\(TerminalStyle.yellow("Dry-run: "))"
                    + "\(TerminalStyle.dim("no git add / git commit."))"
            )
            return
        }

        while true {
            printSuggestion(message)

            switch try prompts.askReview() {
            case .abort:
                throw SwitError.aborted
            case .edit:
                message = try prompts.editMessage(message)
            case .commit:
                let final = message.trimmingCharacters(in: .whitespacesAndNewlines)
                if final.isEmpty {
                    throw SwitError.emptyMessage
                }
                try git.stage(mode: mode)
                let hash = try git.commit(message: final)
                prompts.printLine("\(TerminalStyle.green("Commit \(hash) created."))")
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
        let raw = try await ollama.chat(
            system: CommitPrompt.system, user: CommitPrompt.user(diff: diff))
        var message = CommitMessage.normalize(raw)
        if CommitMessage.isValid(message) {
            return message
        }

        prompts.printLine(
            "\(TerminalStyle.red("The suggestion doesn't fit the pattern; second attempt …"))"
        )
        let retryRaw = try await ollama.chat(
            system: CommitPrompt.system, user: CommitPrompt.retry(previous: message)
        )

        message = CommitMessage.normalize(retryRaw)

        if !CommitMessage.isValid(message) {
            prompts.printLine(
                TerminalStyle.yellow(
                    "Warning: The message does not follow the conventions for commits. You can still edit it."
                )
            )
        }
        return message
    }

    private func printSuggestion(_ message: String) {
        prompts.printLine(
            TerminalStyle.bold(TerminalStyle.yellow(TerminalStyle.bold("Suggestion:"))))

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

        list(TerminalStyle.green("S"), status.staged)
        list(TerminalStyle.yellow("M"), status.unstaged)
        list(TerminalStyle.cyan("?"), status.untracked)
    }
}
