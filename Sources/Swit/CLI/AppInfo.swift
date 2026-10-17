// Sources/Swit/CLI/AppInfo.swift

import Foundation

enum AppInfo {
    static let name = "swit"
    static let description = "Swift Git Terminal Helper"
    static let version = "1.1.0"
    static let abstract = "Git All-Rounder: Local Ollama support for Git workflows."
    static let discussion = """
        `swit commit` suggests a Conventional Commit message with a local Ollama model.
        A commit is created only after explicit confirmation.
        """
    static let updateManifestURL = URL(
        string: "https://raw.githubusercontent.com/beri336/swit/main/version.json"
    )!
}
