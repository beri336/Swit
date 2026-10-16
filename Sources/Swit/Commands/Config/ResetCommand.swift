import ArgumentParser
import Foundation

struct ResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Resets the configuration to the default values."
    )

    func run() throws {
        do {
            let repositoryPath = FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)
            let store = ConfigurationStore(repositoryPath: git.repoPath)

            try store.reset()

            print(
                TerminalStyle.styled(
                    "Configurations were reset to the default values.",
                    foreground: .yellow,
                    attributes: [.bold])
            )
            print(
                TerminalStyle.styled(
                    "File: \(store.fileURL.path)",
                    foreground: .brightGreen))
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
