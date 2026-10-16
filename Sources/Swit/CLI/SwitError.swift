// Sources/Swit/CLI/SwitError.swift

import Foundation

enum SwitError: Error, LocalizedError, CustomStringConvertible, Equatable {
    case gitNotFound
    case noChanges
    case nothingStaged
    case noTrackedChanges
    case emptyDiff
    case emptyMessage
    case aborted
    case notInteractive
    case invalidContextWindow(Int)
    case invalidTemperature(Double)
    case invalidKeepAlive(String)
    case notAGitRepo(String)
    case invalidHost(String)
    case ollamaUnreachable(String)
    case ollamaModelMissing(String)
    case ollamaFailed(String)
    case invalidConfiguration(String)
    case noOllamaModels(String)
    case gitFailed(command: String, message: String)

    var description: String {
        switch self {
            case .gitNotFound:
                return TerminalStyle.styled(
                    "Git was not found. Install Git and make sure it is in your PATH.",
                    foreground: .red,
                    attributes: [.bold])

            case .notAGitRepo(let path):
                return TerminalStyle.styled(
                    "No Git repository found in '\(path)'",
                    foreground: .red,
                    attributes: [.bold])

            case .noChanges:
                return TerminalStyle.styled(
                    "No changes found. Nothing to commit.",
                    foreground: .gray)

            case .nothingStaged:
                return TerminalStyle.styled(
                    "Nothing staged. Run `git add` first or choose a different staging mode.",
                    foreground: .gray)

            case .noTrackedChanges:
                return TerminalStyle.styled(
                    "No changes found in tracked files. Choose 'all' to include new files.",
                    foreground: .gray)

            case .emptyDiff:
                return TerminalStyle.styled(
                    "The diff for the selected mode is empty. Nothing to commit.",
                    foreground: .gray)

            case .gitFailed(let command, let message):
                let detail = message.isEmpty ? "Unknown error" : message
                return TerminalStyle.styled(
                    "git \(command) is failed: \(detail)",
                    foreground: .red,
                    attributes: [.bold])

            case .invalidHost(let host):
                return TerminalStyle.styled(
                    "Invalid Ollama host: \(host). Example: http://127.0.0.1:11434",
                    foreground: .magenta,
                    attributes: [.italic])

            case .ollamaUnreachable(let host):
                return TerminalStyle.styled(
                    """
                    Ollama is not available at \(host)
                    Start the service with: ollama serve
                    """,
                    foreground: .magenta,
                    attributes: [.italic])

            case .ollamaModelMissing(let model):
                return TerminalStyle.styled(
                    """
                    Model '\(model)' was not found.
                    Load it using: ollama pull \(model)
                    """,
                    foreground: .magenta,
                    attributes: [.italic])

            case .ollamaFailed(let message):
                return TerminalStyle.styled(
                    "Ollama error: \(message)",
                    foreground: .red,
                    attributes: [.italic])

            case .emptyMessage:
                return TerminalStyle.styled(
                    "Empty commit message. Aborted.",
                    foreground: .yellow,
                    attributes: [.bold])

            case .aborted:
                return TerminalStyle.styled(
                    "Aborted.",
                    foreground: .red,
                    attributes: [.bold])

            case .notInteractive:
                return TerminalStyle.styled(
                    "This command requires an interactive terminal (or use --dry-run).",
                    foreground: .yellow,
                    attributes: [.bold])

            case .invalidConfiguration(let path):
                return TerminalStyle.styled(
                    """
                    Invalid configuration file: \(path)
                    Check the JSON syntax or delete the file so that swit uses the default values.
                    """,
                    foreground: .red,
                    attributes: [.bold])

            case .noOllamaModels(let host):
                return TerminalStyle.styled(
                    """
                    No local Ollama models found at \(host).
                    First, load a model, for example with:
                    ollama pull qwen2.5-coder:7b
                    """,
                    foreground: .red,
                    attributes: [.bold])

            case .invalidTemperature(let value):
                return TerminalStyle.styled(
                    "Invalid temperature: \(value). Valid values range from 0.0 to 2.0.",
                    foreground: .magenta,
                    attributes: [.italic])

            case .invalidContextWindow(let value):
                return TerminalStyle.styled(
                    "Invalid context window: \(value). The value must be greater than 0.",
                    foreground: .magenta,
                    attributes: [.italic])

            case .invalidKeepAlive(let value):
                return TerminalStyle.styled(
                    """
                    Invalid memory retention time: \(value).
                    Valid values include, for example, 30s, 5m, 2h, 1d, as well as 0 to unload immediately or -1 to keep.
                    """, foreground: .magenta,
                    attributes: [.italic])
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
