// Sources/Swit/Commands/CommitCommand.swift

import ArgumentParser
import Foundation

struct CommitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "commit",
        abstract: "Proposal for a conventional commit message via Ollama; commit after confirmation."
    )

    @Argument(help: "Path to the Git repository. Default: current directory.")
    var path: String?

    @Option(name: .long, help: "Ollama-Modell.")
    var model: String = "qwen2.5-coder:7b"

    @Option(name: .long, help: "Ollama-Host-URL.")
    var host: String = "http://127.0.0.1:11434"

    @Option(name: .long, help: "Staging-Mode: staged-only, tracked, all. Standard: System will prompt interactively.")
    var staging: StagingMode?

    @Flag(name: .long, help: "Just display the suggested message; do not run `git add` or `git commit`.")
    var dryRun: Bool = false

    func run() async throws {
        do {
            let repoPath = path ?? FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repoPath)
            let ollama = try OllamaClient(host: host, model: model)
            let flow = CommitFlow(
                git: git,
                ollama: ollama,
                stagingMode: staging,
                dryRun: dryRun)
            try await flow.run()
        } catch let error as GithError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
