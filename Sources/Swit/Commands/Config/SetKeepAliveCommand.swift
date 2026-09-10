// Sources/Swit/Commands/Config/SetKeepAliveCommand.swift

import ArgumentParser
import Foundation

struct SetKeepAliveCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keep-alive",
        abstract: "Changes how long Ollama keeps a model loaded."
    )

    func run() throws {
        do {
            let prompts = Prompts()
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            var configuration = try store.load()

            configuration.keepAlive = try prompts.askKeepAlive(
                current: configuration.keepAlive
            )

            try store.save(configuration)

            prompts.printLine(
                "Keep alive set: \(configuration.keepAlive)"
            )
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
