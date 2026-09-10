// Sources/Swit/Commands/Config/ShowCommand.swift

import Foundation
import ArgumentParser

struct ShowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Zeigt die aktuelle Konfiguration."
    )

    func run() throws {
        do {
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            let configuration = try store.load()

            print("swit configuration")
            print()
            print("Model:           \(configuration.model)")
            print("Host:            \(configuration.host)")
            print("Temperature:     \(configuration.temperature)")
            print("Context window:  \(configuration.contextWindow)")
            print("Keep alive:      \(configuration.keepAlive)")
            print("Path:            \(store.fileURL.path)")
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
