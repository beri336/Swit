// Sources/Swit/Commit/CommitFlow.swift

import Foundation

struct CommitFlow {
    let git: GitClient
    let ollama: OllamaClient
    let stagingMode: StagingMode?
    let dryRun: Bool
    var verbose: Bool = false

    private let prompts = Prompts()

    func run() async throws {
        async let updateVersion = UpdateChecker(manifestURL: AppInfo.updateManifestURL)
            .availableVersion(current: AppInfo.version)

        let ollamaVersion = try await ollama.version()
        let availableVersion = await updateVersion
        prompts.printBanner(ollamaVersion: ollamaVersion,
                            availableVersion: availableVersion)

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

        let snapshot = try git.repositorySnapshot(mode: mode)
        let diff = try git.previewDiff(mode: mode)

        guard try git.repositorySnapshot(mode: mode) == snapshot else {
            throw SwitError.repositoryChanged
        }

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

                case .regenerate:
                    prompts.printLine(TerminalStyle.styled("Generating another suggestion …",
                                                           foreground: .cyan,
                                                           attributes: [.bold]))
                    message = try await suggestMessage(diff: diff)

                case .diff:
                    printDiff(diff)

                case .commit:
                    let final = message.trimmingCharacters(in: .whitespacesAndNewlines)

                    if final.isEmpty {
                        throw SwitError.emptyMessage
                    }

                    guard try git.repositorySnapshot(mode: mode) == snapshot else {
                        throw SwitError.repositoryChanged
                    }

                    try git.stage(mode: mode)

                    let stagedSnapshot = try git.repositorySnapshot(mode: .stagedOnly)

                    guard stagedSnapshot.head == snapshot.head,
                          stagedSnapshot.indexTree == snapshot.indexTree else {
                        throw SwitError.repositoryChanged
                    }

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

        var message = CommitMessage.normalize(raw.content) // TODO

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
            user: CommitPrompt.retry(previous: message, diff: diff)
        )

        message = CommitMessage.normalize(retryRaw.content)

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

    private func printDiff(_ diff: String) {
        prompts.printLine()
        prompts.printLine(TerminalStyle.styled("Diff used for this suggestion:",
                                               foreground: .yellow,
                                               attributes: [.bold]))
        prompts.printLine()

        for line in diff.split(separator: "\n", omittingEmptySubsequences: false) {
            let text = String(line)

            if text.hasPrefix("+++") || text.hasPrefix("---") {
                prompts.printLine(TerminalStyle.styled(text,
                                                       foreground: .cyan,
                                                       attributes: [.bold]))
            } else if text.hasPrefix("+") {
                prompts.printLine(TerminalStyle.green(text))
            } else if text.hasPrefix("-") {
                prompts.printLine(TerminalStyle.red(text))
            } else if text.hasPrefix("@@") {
                prompts.printLine(TerminalStyle.magenta(text))
            } else if text.hasPrefix("diff --git") || text.hasPrefix("=== NEW FILE:") {
                prompts.printLine(TerminalStyle.styled(text,
                                                       foreground: .cyan,
                                                       attributes: [.bold]))
            } else {
                prompts.printLine(text)
            }
        }

        prompts.printLine()
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

    private func chatWithSpinner(system: String,
                                 user: String
    ) async throws -> OllamaChatResult {
        guard prompts.isInteractive else {
            let result = try await ollama.chat(
                system: system,
                user: user
            )

            printGenerationDetails(result)
            return result
        }

        let spinner = Task<Void, Never> {
            let frames = [
                "⠋", "⠙", "⠹", "⠸", "⠼",
                "⠴", "⠦", "⠧", "⠇", "⠏",
            ]
            let message = TerminalStyle.brightGreen(
                "Generating commit message …"
            )
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
            let result = try await ollama.chat(
                system: system,
                user: user
            )

            spinner.cancel()
            await spinner.value
            Stderr.write("\r\u{001B}[2K")

            printGenerationDetails(result)
            return result
        } catch {
            spinner.cancel()
            await spinner.value
            Stderr.write("\r\u{001B}[2K")

            throw error
        }
    }

    private func printGenerationDetails(_ result: OllamaChatResult) {
        guard verbose else { return }
        
        func printDetail(_ label: String, _ value: String) {
            let title = TerminalStyle.styled(
                label.padding(
                    toLength: 19,
                    withPad: " ",
                    startingAt: 0
                ),
                foreground: .yellow,
                attributes: [.bold]
            )

            prompts.printLine("  \(title)\(TerminalStyle.gray(value))")
        }

        func durationText(_ seconds: Double?) -> String {
            guard let seconds else {
                return "n/a"
            }

            return String(
                format: "%.2f sec",
                locale: Locale(identifier: "en_US_POSIX"),
                seconds
            )
        }

        prompts.printLine()
        prompts.printLine(TerminalStyle.styled("Generation details",
                                               foreground: .yellow,
                                               attributes: [.bold]))

        printDetail("Model:",
                    ollama.model)
        printDetail("Context window:",
                    "\(ollama.contextWindow)")
        printDetail("Temperature:",
                    "\(ollama.temperature)")
        printDetail("Ollama total time:",
                    durationText(result.totalDurationSeconds))
        printDetail("Model load time:",
                    durationText(result.loadDurationSeconds))
        printDetail("Output time:",
                    durationText(result.outputDurationSeconds))
        printDetail("Prompt tokens:",
                    result.promptEvalCount.map { String($0) } ?? "n/a")
        printDetail("Output tokens:",
                    result.evalCount.map { String($0) } ?? "n/a")
        printDetail("Stop reason:",
                    result.doneReason ?? "n/a")

        prompts.printLine()
    }
}
