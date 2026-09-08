// Sources/Gith/Commands/CommitCommand.swift

import ArgumentParser
import Foundation

struct CommitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "commit",
        abstract: "Vorschlag für eine Conventional-Commit-Message per Ollama, Commit nach Bestätigung."
    )

    @Argument(help: "Pfad zum Git-Repository. Standard: aktuelles Verzeichnis.")
    var path: String?

    @Option(name: .long, help: "Ollama-Modell.")
    var model: String = "qwen2.5-coder:7b"

    @Option(name: .long, help: "Ollama-Host-URL.")
    var host: String = "http://127.0.0.1:11434"

    @Flag(name: .long, help: "Nur die vorgeschlagene Message ausgeben, kein git add / git commit.")
    var dryRun: Bool = false

    func run() async throws {
        do {
            let repoPath = path ?? FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repoPath)
            let ollama = try OllamaClient(host: host, model: model)
            try await CommitFlow(git: git, ollama: ollama, dryRun: dryRun).run()
        } catch let error as GithError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
