// Sources/Swit/Commands/Config/SetTemperatureCommand.swift

import ArgumentParser
import Foundation

struct SetTemperatureCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "temperature",
        abstract: "Changes the Ollama temperature."
    )

    func run() throws {
        do {
            let prompts = Prompts()
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            var configuration = try store.load()

            configuration.temperature = try prompts.askTemperature(
                current: configuration.temperature
            )
            try store.save(configuration)

            prompts.printLine(
                TerminalStyle.styled(
                    "Ollama temperature set to: ",
                    foreground: .green,
                    attributes: [.bold]
                ) + TerminalStyle.gray("\(configuration.temperature)")
            )
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
