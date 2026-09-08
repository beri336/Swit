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
            throw GithError.notInteractive
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
        Stderr.write("Staging? [1] only staged  [2] tracked  [3] all\n> ")
        guard let raw = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            throw GithError.aborted
        }
        switch raw {
        case "1", "s", "staged", "only staged":
            return .stagedOnly
        case "2", "t", "tracked":
            return .tracked
        case "3", "a", "all":
            return .all
        default:
            Stderr.write("Invalid selection. Please enter 1, 2, or 3.\n")
            return try askStagingMode()
        }
    }

    func askReview() throws -> ReviewChoice {
        try requireInteractive()
        Stderr.write("[y] commit  [e] edit  [n] abort\n> ")
        guard let raw = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            throw GithError.aborted
        }
        switch raw {
        case "y", "yes", "j", "":
            return .commit
        case "e", "edit":
            return .edit
        case "n", "no", "q", "abort":
            return .abort
        default:
            Stderr.write("Invalid selection. Please enter y, e, or n.\n")
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
            throw GithError.emptyMessage
        }
        return edited
    }

    func printLine(_ text: String) {
        Stderr.write(text + "\n")
    }
}

enum Stderr {
    static func write(_ text: String) {
        try? FileHandle.standardError.write(contentsOf: Data(text.utf8))
    }
}
