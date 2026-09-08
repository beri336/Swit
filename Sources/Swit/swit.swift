// Sources/Swit/swit.swift

import ArgumentParser

@main
struct Swit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swit",
        abstract: "Git-Allrounder: lokale Ollama-Hilfe für Git-Workflows.",
        discussion: "v1 bietet `swit commit` — Conventional-Commit-Vorschlag per lokalem Ollama, Commit erst nach Bestätigung.",
        version: "0.1.0",
        subcommands: [CommitCommand.self]
    )
}
