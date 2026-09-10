// Sources/Swit/Commands/CommitCommand.swift

import ArgumentParser

import Foundation

struct CommitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "commit",
        abstract:
            "Proposal for a conventional commit message via Ollama; commit after confirmation."
    )

    @Argument(help: "Path to the Git repository. Default: current directory.")
    var path: String?

    @Option(name: .long, help: "Ollama model for this prompt.")
    var model: String?

    @Option(name: .long, help: "Ollama host URL for this request.")
    var host: String?

    @Option(name: .long, help: "Ollama temperature from 0.0 to 2.0 for this call.")
    var temperature: Double?

    @Option(name: .long, help: "Ollama context window in tokens for this call.")
    var contextWindow: Int?

    @Option(name: .long, help: "How long Ollama keeps the model loaded, e.g., 5m.")
    var keepAlive: String?

    @Option(
        name: .long,
        help: "Staging-Mode: staged-only, tracked, all. Standard: System will prompt interactively."
    )
    var staging: StagingMode?

    @Flag(
        name: .long,
        help: "Just display the suggested message; do not run `git add` or `git commit`.")
    var dryRun: Bool = false

    func run() async throws {
        do {
            let repositoryPath = path ?? FileManager.default.currentDirectoryPath
            let git = try GitClient.open(at: repositoryPath)

            let store = ConfigurationStore(repositoryPath: git.repoPath)
            let configuration = try store.load()

            let ollama = try OllamaClient(
                host: host ?? configuration.host,
                model: model ?? configuration.model,
                temperature: temperature ?? configuration.temperature,
                contextWindow: contextWindow ?? configuration.contextWindow,
                keepAlive: keepAlive ?? configuration.keepAlive
            )

            let flow = CommitFlow(
                git: git,
                ollama: ollama,
                stagingMode: staging,
                dryRun: dryRun
            )

            try await flow.run()
        } catch let error as SwitError {
            Stderr.write(error.description + "\n")
            throw ExitCode(error.exitCode)
        }
    }
}
