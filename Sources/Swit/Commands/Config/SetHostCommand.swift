// Sources/Swit/Commands/Config/SetHostCommand.swift

import ArgumentParser

struct SetHostCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "host",
        abstract: "Changes the Ollama host."
    )

    func run() throws {
        do {
            let prompts = Prompts()
            try prompts.requireInteractive()

            let store = ConfigurationStore()
            var configuration = try store.load()

            let host = try prompts.askHost(current: configuration.host)

            _ = try OllamaClient(
                host: host,
                model: configuration.model
            )

            configuration.host = host
            try store.save(configuration)

            prompts.printLine("Ollama host set to \(host).")
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
