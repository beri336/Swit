// Sources/Swit/Configuration/ConfigurationStore.swift

import Foundation

struct ConfigurationStore {
    let fileURL: URL
    private let fileManager: FileManager

    init(
        fileURL: URL = ConfigurationStore.defaultFileURL(),
        fileManager: FileManager = .default
    ) {
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
            withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(configuration)

        try data.write(to: fileURL, options: .atomic)
    }

    static func defaultFileURL() -> URL {
        #if os(macOS)
            let applicationSupportURL = FileManager.default.urls(
                for: .applicationDirectory,
                in: .userDomainMask)[0]

            return
                applicationSupportURL
                .appendingPathComponent(AppInfo.name, isDirectory: true)
                .appendingPathComponent("config.json")
        #else
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

            return
                homeDirectory
                .appendingPathComponent(".config", isDirectory: true)
                .appendingPathComponent(AppInfo.name, isDirectory: true)
                .appendingPathComponent("config.json")
        #endif
    }
}
