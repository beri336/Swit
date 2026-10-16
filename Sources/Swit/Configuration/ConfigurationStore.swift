// Sources/Swit/Configuration/ConfigurationStore.swift

import Foundation

struct ConfigurationStore {
    let fileURL: URL
    private let fileManager: FileManager

    init(repositoryPath: String,
         fileManager: FileManager = .default)
    {
        self.fileURL = URL(fileURLWithPath: repositoryPath, isDirectory: true)
            .appendingPathComponent(".git", isDirectory: true)
            .appendingPathComponent(AppInfo.name, isDirectory: true)
            .appendingPathComponent("config.json")

        self.fileManager = fileManager
    }

    init(fileURL: URL,
         fileManager: FileManager = .default)
    {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func load() throws -> AppConfiguration {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .default
        }

        let data = try Data(contentsOf: fileURL)

        do {
            return try JSONDecoder().decode(AppConfiguration.self, from: data)
        } catch {
            throw SwitError.invalidConfiguration(fileURL.path)
        }
    }

    func save(_ configuration: AppConfiguration) throws {
        let directoryURL = fileURL.deletingLastPathComponent()

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(configuration)

        try data.write(
            to: fileURL,
            options: Data.WritingOptions.atomic
        )
    }

    func reset() throws {
        try save(.default)
    }
}
