// Sources/Swit/Commands/Config/SetCommand.swift

import ArgumentParser

struct SetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Changes a configuration value.",
        subcommands: [
            SetModelCommand.self,
            SetHostCommand.self,
            SetTemperatureCommand.self,
            SetContextWindowCommand.self,
            SetKeepAliveCommand.self,
        ]
    )
}
