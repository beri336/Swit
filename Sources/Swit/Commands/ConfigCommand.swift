// Sources/Swit/Commands/ConfigCommand.swift

import ArgumentParser

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manages the swit configuration file.",
        subcommands: [
            ShowCommand.self,
            SetCommand.self,
        ]
    )
}
