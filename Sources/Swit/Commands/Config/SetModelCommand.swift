// Sources/Swit/Commands/Config/SetModelCommand.swift

import ArgumentParser
import Foundation

struct SetModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Selects a locally installed Ollama model."
    )

    func run() async throws {
        do {
            let prompts = Prompts()
            try prompts.requireInteractive()

            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            var configuration = try store.load()

            let ollama = try OllamaClient(
                host: configuration.host,
                model: configuration.model,
                temperature: configuration.temperature,
                contextWindow: configuration.contextWindow,
                keepAlive: configuration.keepAlive
            )

            prompts.printLine("Loading available Ollama models …")

            let models = try await ollama.listModels()

            let selectedModel = try prompts.askModel(from: models)

            configuration.model = selectedModel.name
            try store.save(configuration)

            prompts.printLine("Set standard model: \(selectedModel.name)")
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
