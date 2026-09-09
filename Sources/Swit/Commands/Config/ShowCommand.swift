// Sources/Swit/Commands/Config/ShowCommand.swift

import ArgumentParser

struct ShowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Zeigt die aktuelle Konfiguration."
    )

    func run() throws {
        do {
            let store = ConfigurationStore()
            let configuration = try store.load()

            print("swit configuration")
            print()
            print("Model:       \(configuration.model)")
            print("Host:        \(configuration.host)")
            print("Temperature: \(configuration.temperature)")
            print("Path:        \(store.fileURL.path)")
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
