// Sources/Swit/Commands/Config/SetContextWindowCommand.swift

import ArgumentParser
import Foundation

struct SetContextWindowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "context-window",
        abstract: "Changes the context window for Ollama."
    )

    func run() throws {
        do {
            let prompts = Prompts()
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            var configuration = try store.load()

            configuration.contextWindow = try prompts.askContextWindow(
                current: configuration.contextWindow
            )

            try store.save(configuration)

            prompts.printLine(
                TerminalStyle.styled(
                    "Context window set to: ",
                    foreground: .green,
                    attributes: [.bold]
                ) + TerminalStyle.gray("\(configuration.contextWindow)")
            )
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
