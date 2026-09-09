// Sources/Gith/CLI/Prompts.swift

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
            "[1] staged",
            "[2] tracked",
            "[3] all",
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
        default:
            Stderr.write(TerminalStyle.yellow("Invalid selection. Enter 1, 2, or 3.") + "\n")

            return try askStagingMode()
        }
    }

    func askReview() throws -> ReviewChoice {
        try requireInteractive()

        let prompt =
            "\(TerminalStyle.green("[y] Commit"))  " + "\(TerminalStyle.yellow("[e] Edit"))  "
            + "\(TerminalStyle.red("[n] Abort"))\n> "

        Stderr.write(prompt)

        guard let raw = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        else {
            throw SwitError.aborted
        }
        switch raw {
        case "y", "yes", "j", "":
            return .commit
        case "e", "edit":
            return .edit
        case "n", "no", "q", "abort":
            return .abort
        default:
            Stderr.write(TerminalStyle.yellow("Invalid selection. Enter y, e, or n.") + "\n")

            return try askReview()
        }
    }

    func askModel(from models: [OllamaModel]) throws -> OllamaModel {
        try requireInteractive()

        printLine("")
        printLine("Available Ollama models:")

        for (i, model) in models.enumerated() {
            printLine("  [\(i + 1)] \(model.name)")
        }

        printLine("")
        Stderr.write("Choose a model [1-\(models.count)] or [q] to cancel:\n> ")

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

            Stderr.write("Invalid selection. Please enter a number between 1 and \(models.count) or 'q'.\n> ")
        }

        throw SwitError.aborted
    }

    func askHost(current: String) throws -> String {
        try requireInteractive()

        printLine("Current Ollama host:")
        printLine("  \(current)")
        printLine("")
        Stderr.write("Enter the new Ollama host:\n> ")

        guard let raw = readLine() else {
            throw SwitError.aborted
        }

        let host = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !host.isEmpty else {
            throw SwitError.aborted
        }

        return host
    }

    func editMessage(_ current: String) throws -> String {
        try requireInteractive()
        Stderr.write(
            """
            Edit the message. End with a line that contains only a period (.).
            Current:

            \(current)

            New message:

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

    func printBanner() {
        let title = TerminalStyle.bold(
            TerminalStyle.cyan("SWIT · \(AppInfo.description)")
        )
        let version = TerminalStyle.dim("v\(AppInfo.version)")

        printLine("┌──────────────────────────────────────┐")
        printLine("│  \(title)")
        printLine("│  \(version)")
        printLine("└──────────────────────────────────────┘")
        printLine()
    }
}
enum Stderr {
    static func write(_ text: String) {
        try? FileHandle.standardError.write(contentsOf: Data(text.utf8))
    }
}
