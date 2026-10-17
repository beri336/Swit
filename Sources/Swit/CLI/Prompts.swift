// Sources/Swit/CLI/Prompts.swift

import Foundation

#if !os(Windows)
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #endif
#endif

struct Prompts {
    enum ReviewChoice {
        case commit
        case edit
        case regenerate
        case diff
        case abort
    }

    func requireInteractive() throws {
        guard isInteractive else {
            throw SwitError.notInteractive
        }
    }

    var isInteractive: Bool {
        #if os(Windows)
            return true
        #else
            return isatty(fileno(stdin)) != 0
        #endif
    }

    func askStagingMode() throws -> StagingMode {
        try requireInteractive()

        let prompt = [
            TerminalStyle.bold("Staging mode"),
            "\(TerminalStyle.magenta("[1] staged"))",
            "\(TerminalStyle.yellow("[2] tracked"))",
            "\(TerminalStyle.green("[3] all"))",
            "\(TerminalStyle.gray("[q] quit"))",
        ].joined(separator: "  ")

        Stderr.write(prompt + "\n> ")

        guard let raw = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        else {
            throw SwitError.aborted
        }

        switch raw {
        case "1", "s", "staged", "only staged":
            return .stagedOnly
        case "2", "t", "tracked":
            return .tracked
        case "3", "a", "all":
            return .all
        case "q", "quit":
            throw SwitError.aborted
        default:
            Stderr.write(
                TerminalStyle.red(
                    TerminalStyle.bold("Invalid selection. Enter 1, 2, or 3.")) + "\n"
            )

            return try askStagingMode()
        }
    }

    func askReview() throws -> ReviewChoice {
        try requireInteractive()

        let prompt = [
            TerminalStyle.green("[y] Commit"),
            TerminalStyle.yellow("[e] Edit"),
            TerminalStyle.cyan("[r] Regenerate"),
            TerminalStyle.blue("[d] Diff"),
            TerminalStyle.red("[n] Abort"),
        ].joined(separator: "  ")

        while true {
            Stderr.write(prompt +
            "\n" +
            TerminalStyle.gray("> "))

            guard let raw = readLine() else {
                throw SwitError.aborted
            }

            let input = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            
            switch input {
                case "y", "yes", "j", "":
                    return .commit
                case "e", "edit":
                    return .edit
                case "r", "regenerate":
                    return .regenerate
                case "d", "diff":
                    return .diff
                case "n", "no", "q", "abort", "quit":
                    return .abort

                default:
                printLine(
                    TerminalStyle.styled("Invalid selection. Enter y, e or n.\n",
                        foreground: .red,
                        attributes: [.bold]))

                    return try askReview()
            }
        }
    }

    func askModel(from models: [OllamaModel]) throws -> OllamaModel {
        try requireInteractive()

        printLine(
            TerminalStyle.styled(
                "\nAvailable Ollama models: ",
                foreground: .green,
                attributes: [.bold]
            )
        )

        for (i, model) in models.enumerated() {
            printLine(TerminalStyle.gray("  [\(i + 1)] \(model.name)"))
        }

        Stderr.write(
            TerminalStyle.green("\nChoose a model [1-\(models.count)] or [q] to cancel:")
                + "\n"
                + TerminalStyle.gray("> ")
        )

        while let raw = readLine() {
            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            if input.lowercased() == "q" {
                throw SwitError.aborted
            }

            if let num = Int(input),
                models.indices.contains(num - 1)
            {
                return models[num - 1]
            }

            Stderr.write(
                TerminalStyle.red(
                    TerminalStyle.bold(
                        "Invalid selection. Please enter a number between 1 and \(models.count) or 'q'."
                    )) + "\n" + TerminalStyle.gray("> ")
            )
        }

        throw SwitError.aborted
    }

    func askHost(current: String) throws -> String {
        try requireInteractive()

        printLine(
            TerminalStyle.styled(
                "Current Ollama host: ",
                foreground: .green,
                attributes: [.bold]
            ) + TerminalStyle.gray("\(current)")
        )

        Stderr.write(
            TerminalStyle.green("Enter the new Ollama host:")
                + "\n"
                + TerminalStyle.gray("> ")
        )

        guard let raw = readLine() else {
            throw SwitError.aborted
        }

        let host = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !host.isEmpty else {
            throw SwitError.aborted
        }

        return host
    }

    func askTemperature(current: Double) throws -> Double {
        try requireInteractive()

        printLine(
            TerminalStyle.styled(
                "Current temperature: ",
                foreground: .green,
                attributes: [.bold]
            ) + TerminalStyle.gray("\(current)")
        )

        Stderr.write(
            TerminalStyle.green("New temperature (0.0 - 2.0):")
                + "\n"
                + TerminalStyle.gray("> ")
        )

        guard let raw = readLine() else {
            throw SwitError.aborted
        }

        let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let temerature = Double(input) else {
            throw SwitError.invalidTemperature(.nan)
        }

        guard ConfigurationValidator.isValid(temperature: temerature) else {
            throw SwitError.invalidTemperature(temerature)
        }

        return temerature
    }

    func askContextWindow(current: Int) throws -> Int {
        try requireInteractive()

        let minTokens = ConfigurationValidator.minimumContextWindow
        let maxTokens = ConfigurationValidator.maximumContextWindow
        let defaultValue = AppConfiguration.defaultContextWindow

        printLine(
            TerminalStyle.styled("Current context window: ",
                                 foreground: .green,
                                 attributes: [.bold]) +
                TerminalStyle.gray("\(current)")
        )

        while true {
            Stderr.write(
                TerminalStyle.green(
                    "New context window in tokens (\(minTokens)-\(maxTokens), default \(defaultValue); [q] cancel:"
                ) + "\n" + TerminalStyle.gray("> ")
            )

            guard let raw = readLine() else {
                throw SwitError.aborted
            }

            let input = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            if ["q", "quit"].contains(input.lowercased()) {
                throw SwitError.aborted
            }

            guard let contextWindow = Int(input) else {
                printLine(
                    TerminalStyle.styled(
                        "Invalid input. Enter a whole number between \(minTokens) and \(maxTokens), or q to cancel.",
                        foreground: .yellow,
                        attributes: [.bold])
                )
                continue
            }

            guard ConfigurationValidator.isValid(contextWindow: contextWindow) else {
                printLine(
                    SwitError.invalidContextWindow(contextWindow).description
                )
                continue
            }

            return contextWindow
        }
    }

    func askKeepAlive(current: String) throws -> String {
        try requireInteractive()

        printLine(
            TerminalStyle.styled(
                "Current keep alive: ",
                foreground: .green,
                attributes: [.bold]
            )
                + TerminalStyle.gray("\(current)")
        )

        Stderr.write(
            TerminalStyle.green(
                "New keep alive (for example 30s, 5m, 2h, 1d; 0 = unload, -1 = keep alive):")
                + "\n"
                + TerminalStyle.gray("> ")
        )

        guard let raw = readLine() else {
            throw SwitError.aborted
        }

        let keepAlive = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard ConfigurationValidator.isValid(keepAlive: keepAlive) else {
            throw SwitError.invalidKeepAlive(keepAlive)
        }

        return keepAlive
    }

    func editMessage(_ current: String) throws -> String {
        try requireInteractive()
        Stderr.write(
            """
            \(TerminalStyle.yellow(TerminalStyle.bold("Edit the message. End with a line that contains only a period (.).")))
            \(TerminalStyle.magenta(TerminalStyle.bold("Current:")))

            \(current)

            \(TerminalStyle.magenta(TerminalStyle.bold("New message:")))

            """
        )

        var lines: [String] = []
        while let line = readLine() {
            if line == "." {
                break
            }
            lines.append(line)
        }
        let edited = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if edited.isEmpty {
            throw SwitError.emptyMessage
        }
        return edited
    }

    func printLine(_ text: String = "") {
        Stderr.write(text + "\n")
    }

    func printBanner(
        ollamaVersion: String? = nil,
        availableVersion: String? = nil
    ) {
        let title = TerminalStyle.bold(
            TerminalStyle.styled(
                "SWIT · \(AppInfo.description)",
                foreground: .cyan,
                attributes: [.bold])
        )

        var version = TerminalStyle.dim("Swit v\(AppInfo.version)")

        if let availableVersion {
            version +=
                " " +
                TerminalStyle.styled(
                    "(update available: v\(availableVersion))",
                    foreground: .yellow,
                    attributes: [.bold])
        }

        let ollamaLabel: String
        if let ollamaVersion {
            ollamaLabel = TerminalStyle.dim("Ollama v\(ollamaVersion)")
        } else {
            ollamaLabel = TerminalStyle.dim("Ollama unavailable")
        }

        printLine("┌──────────────────────────────────────┐")
        printLine("│  \(title)")
        printLine("│  \(version)")
        printLine("│  \(ollamaLabel)")
        printLine("└──────────────────────────────────────┘")
        printLine()
    }
}
enum Stderr {
    static func write(_ text: String) {
        try? FileHandle.standardError.write(contentsOf: Data(text.utf8))
    }
}
