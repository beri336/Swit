// Sources/Swit/swit.swift

import ArgumentParser

@main
struct Swit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swit",
        abstract: "Git All-Rounder: Local Ollama support for Git workflows.",
        discussion: "v1 offers 'swit commit' — a conventional commit suggestion via the local Ollama, with the commit made only after confirmation.",
        version: "0.1.0",
        subcommands: [CommitCommand.self]
    )
}
