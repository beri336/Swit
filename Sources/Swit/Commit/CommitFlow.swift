// Sources/Swit/Commit/CommitFlow.swift

import Foundation

struct CommitFlow {
    let git: GitClient
    let ollama: OllamaClient
    let stagingMode: StagingMode?
    let dryRun: Bool

    private let prompts = Prompts()

    func run() async throws {
        let ollamaVersion = try await ollama.version()
        prompts.printBanner(ollamaVersion: ollamaVersion)

        let status = try git.status()

        prompts.printLine(
            TerminalStyle.styled(
                "Repository: ",
                foreground: .yellow,
                attributes: [.bold]
            ) + TerminalStyle.cyan(git.repoPath)
        )

        prompts.printLine(
            TerminalStyle.styled(
                "Changes: ",
                foreground: .yellow,
                attributes: [.bold]
            )
                + TerminalStyle.green("staged \(status.staged.count)") + "  "
                + TerminalStyle.yellow("modified \(status.unstaged.count)") + "  "
                + TerminalStyle.dim("untracked \(status.untracked.count)")
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
            TerminalStyle.styled(
                "Ollama ",
                foreground: .yellow,
                attributes: [.bold]
            )
                + TerminalStyle.dim("creates a suggestion for a conventional commit …")
        )

        prompts.printLine(
            TerminalStyle.styled(
                "Model ",
                foreground: .yellow,
                attributes: [.bold]
            )
                + TerminalStyle.dim(ollama.model)
        )

        var message = try await suggestMessage(diff: diff)

        if dryRun {
            printSuggestion(message)
            prompts.printLine(
                TerminalStyle.styled(
                    "Dry-run: ",
                    foreground: .yellow,
                    attributes: [.bold]
                )
                    + TerminalStyle.dim("no git add / git commit.")
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
                prompts.printLine(
                    TerminalStyle.styled(
                        "Commit \(hash) created.",
                        foreground: .green,
                        attributes: [.bold]
                    )
                )
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
        let raw = try await chatWithSpinner(
            system: CommitPrompt.system,
            user: CommitPrompt.user(diff: diff)
        )

        var message = CommitMessage.normalize(raw)

        if CommitMessage.isValid(message) {
            return message
        }

        prompts.printLine(
            TerminalStyle.styled(
                "The suggestion doesn't fit the pattern, second attempt …",
                foreground: .magenta,
                attributes: [.bold]
            )
        )

        let retryRaw = try await chatWithSpinner(
            system: CommitPrompt.system,
            user: CommitPrompt.retry(previous: message)
        )

        message = CommitMessage.normalize(retryRaw)

        if !CommitMessage.isValid(message) {
            prompts.printLine(
                TerminalStyle.styled(
                    "Warning: The message does not follow the conventions for commits. You can still edit it.",
                    foreground: .yellow,
                    attributes: [.bold]
                )
            )
        }

        return message
    }

    private func printSuggestion(_ message: String) {
        prompts.printLine(
            TerminalStyle.styled(
                "Suggestion:",
                foreground: .yellow,
                attributes: [.bold]
            )
        )

        for line in message.split(separator: "\n", omittingEmptySubsequences: false) {
            prompts.printLine("  \(TerminalStyle.blue(String(line)))")
        }
        prompts.printLine("")
    }

    private func printStatusFiles(_ status: GitStatus) {
        let limit = 12

        func list(_ files: [String],
                  symbol: String,
                  color: TerminalStyle.Color
        ) {
            guard !files.isEmpty else { return }

            let badge = TerminalStyle.styled(
                symbol,
                foreground: color,
                attributes: [.bold]
            )

            for file in files.prefix(limit) {
                prompts.printLine("    \(badge)  \(file)")
            }

            let remaining = files.count - limit

            if remaining > 0 {
                let overflow = TerminalStyle.dim("… +\(remaining) weitere")
                prompts.printLine("    \(badge)  \(overflow)")
            }
        }

        list(status.staged, symbol: "S", color: .green)
        list(status.unstaged, symbol: "M", color: .yellow)
        list(status.untracked, symbol: "?", color: .gray)
    }

    private func chatWithSpinner(system: String, user: String) async throws -> String {
        // without interactive input, no animation
        guard prompts.isInteractive else {
            return try await ollama.chat(system: system, user: user)
        }

        let spinner = Task<Void, Never> {
            let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
            let message = TerminalStyle.brightGreen("Generating commit message …")
            let clock = ContinuousClock()
            let start = clock.now
            var index = 0

            while !Task.isCancelled {
                let seconds = start.duration(to: clock.now).components.seconds
                let frame = TerminalStyle.brightGreen(frames[index])
                let timer = TerminalStyle.gray("(\(seconds) sec)")

                Stderr.write(
                    "\r\u{001B}[2K\(frame) \(message) \(timer)"
                )

                index = (index + 1) % frames.count

                do {
                    try await Task.sleep(for: .milliseconds(80))
                } catch {
                    break
                }
            }
        }

        do {
            let response = try await ollama.chat(system: system, user: user)

            spinner.cancel()
            await spinner.value
            Stderr.write("\r\u{001B}[2K")

            return response
        } catch {
            spinner.cancel()
            await spinner.value
            Stderr.write("\r\u{001B}[2K")

            throw error
        }
    }
}
