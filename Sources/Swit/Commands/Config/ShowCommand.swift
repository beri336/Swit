// Sources/Swit/Commands/Config/ShowCommand.swift

import ArgumentParser
import Foundation

struct ShowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Shows the current configuration."
    )

    func run() throws {
        do {
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)
            let configuration = try store.load()

            func printSetting(_ label: String, _ value: String) {
                let title = TerminalStyle.styled(
                    label.padding(toLength: 17, withPad: " ", startingAt: 0),
                    foreground: .yellow,
                    attributes: [.bold]
                )

                print("  \(title)\(value)")
            }

            print(
                TerminalStyle.styled(
                    "Swit configuration",
                    foreground: .green,
                    attributes: [.bold]
                )
            )
            print()

            printSetting("Model:", TerminalStyle.dim(configuration.model))
            printSetting("Host:", TerminalStyle.dim(configuration.host))
            printSetting("Temperature:", TerminalStyle.dim("\(configuration.temperature)"))
            printSetting("Context window:", TerminalStyle.dim("\(configuration.contextWindow)"))
            printSetting("Keep alive:", TerminalStyle.dim((configuration.keepAlive)))

            print()
            printSetting("Path:", TerminalStyle.dim(store.fileURL.path))
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
