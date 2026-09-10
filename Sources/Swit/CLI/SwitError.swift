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
            return "Invalid Ollama host: \(host). Example: http://127.0.0.1:11434"

        case .ollamaUnreachable(let host):
            return """
                Ollama is not available at \(host)
                Start the service with: ollama serve
                """

        case .ollamaModelMissing(let model):
            return """
                Model '\(model)' was not found.
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

        case .invalidConfiguration(let path):
            return """
                Invalid configuration file: \(path)
                Check the JSON syntax or delete the file so that swit uses the default values.
                """

        case .noOllamaModels(let host):
            return """
                No local Ollama models found at \(host).
                First, load a model, for example with:
                ollama pull qwen2.5-coder:7b
                """

        case .invalidTemperature(let value):
            return "Invalid temperature: \(value). Valid values range from 0.0 to 2.0."

        case .invalidContextWindow(let value):
            return "Invalid context window: \(value). The value must be greater than 0."

        case .invalidKeepAlive(let value):
            return """
                Invalid memory retention time: \(value).
                Valid values include, for example, 30s, 5m, 2h, 1d, as well as 0 to unload immediately or -1 to keep.
                """
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
