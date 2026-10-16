// Sources/Swit/Commands/Config/SetHostCommand.swift

import ArgumentParser
import Foundation

struct SetHostCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "host",
        abstract: "Changes the Ollama host."
    )

    func run() throws {
        do {
            let prompts = Prompts()
            try prompts.requireInteractive()

            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            var configuration = try store.load()

            let host = try prompts.askHost(current: configuration.host)

            _ = try OllamaClient(
                host: host,
                model: configuration.model
            )

            configuration.host = host
            try store.save(configuration)

            prompts.printLine(
                TerminalStyle.styled(
                    "Ollama host set to: ",
                    foreground: .green,
                    attributes: [.bold]
                ) + TerminalStyle.gray("\(host)")
            )
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
