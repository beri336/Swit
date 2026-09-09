// Sources/Swit/swit.swift

import ArgumentParser

@main
struct Swit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: AppInfo.name,
        abstract: AppInfo.abstract,
        discussion: AppInfo.discussion,
        version: AppInfo.version,
        subcommands: [
            CommitCommand.self,
            ConfigCommand.self,
        ]
    )
}
