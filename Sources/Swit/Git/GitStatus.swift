// Sources/Swit/Git/GitStatus.swift

import Foundation

struct GitStatus {
    var staged: [String] = []
    var unstaged: [String] = []
    var untracked: [String] = []

    var isEmpty: Bool {
        staged.isEmpty && unstaged.isEmpty && untracked.isEmpty
    }

    static func parsePorcelain(_ output: String) -> GitStatus {
        var status = GitStatus()

        for rawLine in output.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = String(rawLine)

            guard line.count >= 3 else { continue }

            let indexStatus = line[line.startIndex]
            let workTreeStatus = line[line.index(after: line.startIndex)]
            let pathPart = String(line.dropFirst(3))
            let path = Self.displayPath(from: pathPart)

            if indexStatus == "?" && workTreeStatus == "?" {
                status.untracked.append(path)
                continue
            }
            if indexStatus == "!" {
                continue
            }
            if indexStatus != " " {
                status.staged.append(path)
            }
            if workTreeStatus != " " && workTreeStatus != "?" {
                status.unstaged.append(path)
            }
        }

        return status
    }

    private static func displayPath(from pathPart: String) -> String {
        if let range = pathPart.range(of: " -> ") {
            return String(pathPart[range.upperBound...])
        }

        return pathPart
    }
}
