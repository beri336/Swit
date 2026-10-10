// Sources/Swit/Commit/CommitMessage.swift

import Foundation

enum CommitMessage {
    static let allowedTypes = [
        "feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore",
    ]

    static func normalize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var trimmed = Array(lines.dropFirst())
            if let last = trimmed.last, last.hasPrefix("```") {
                trimmed.removeLast()
            }
            text = trimmed.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    static func isValid(_ message: String) -> Bool {
        guard let firstLine = message.split(separator: "\n", omittingEmptySubsequences: false).first else {
            return false
        }
        let line = String(firstLine).trimmingCharacters(in: .whitespaces)
        let types = allowedTypes.joined(separator: "|")
        let pattern = "^(\(types))(\\([A-Za-z0-9_./-]+\\))?: .{1,100}$"
        return line.range(of: pattern, options: .regularExpression) != nil
    }
}
