// Sources/Swit/CLI/SwitError.swift

import Foundation

enum SwitError: Error, LocalizedError, CustomStringConvertible {
    case gitNotFound
    case notAGitRepo(String)
    case noChanges
    case nothingStaged
    case noTrackedChanges
    case emptyDiff
    case gitFailed(command: String, message: String)
    case invalidHost(String)
    case ollamaUnreachable(String)
    case ollamaModelMissing(String)
    case ollamaFailed(String)
    case emptyMessage
    case aborted
    case notInteractive

    var description: String {
        switch self {
        case .gitNotFound:
            return "Git was not found. Install Git and make sure it is in your PATH."
        case .notAGitRepo(let path):
            return "No Git repository: \(path)"
        case .noChanges:
            return "No changes found. Nothing to commit."
        case .nothingStaged:
            return "Nothing staged. Run `git add` first or choose a different staging mode."
        case .noTrackedChanges:
            return "No changes found in tracked files. Choose 'all' to include new files."
        case .emptyDiff:
            return "The diff for the selected mode is empty. Nothing to commit."
        case .gitFailed(let command, let message):
            let detail = message.isEmpty ? "Unknown error" : message
            return "git \(command) is failed: \(detail)"
        case .invalidHost(let host):
            return "Invalid Ollama host: \(host). Beispiel: http://127.0.0.1:11434"
        case .ollamaUnreachable(let host):
            return """
            Ollama is not available at \(host)
            Start the service with: ollama serve
            """
        case .ollamaModelMissing(let model):
            return """
            Model ‘\(model)’ was not found.
            Load it using: ollama pull \(model)
            """
        case .ollamaFailed(let message):
            return "Ollama error: \(message)"
        case .emptyMessage:
            return "Empty commit message. Aborted."
        case .aborted:
            return "Aborted."
        case .notInteractive:
            return "This command requires an interactive terminal (or use --dry-run)."
        }
    }

    var errorDescription: String? { description }

    var exitCode: Int32 {
        switch self {
        case .aborted:
            return 1
        case .noChanges, .nothingStaged, .noTrackedChanges, .emptyDiff:
            return 2
        default:
            return 1
        }
    }
}
