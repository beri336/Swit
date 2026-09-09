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
