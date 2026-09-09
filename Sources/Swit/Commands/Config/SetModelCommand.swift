// Sources/Swit/Commands/Config/SetModelCommand.swift

import ArgumentParser

struct SetModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "model",
        abstract: "Selects a locally installed Ollama model."
    )

    func run() async throws {
        do {
            let prompts = Prompts()
            try prompts.requireInteractive()

            let store = ConfigurationStore()
            var configuration = try store.load()

            let ollama = try OllamaClient(
                host: configuration.host,
                model: configuration.model
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
