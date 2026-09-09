// Sources/Swit/Configuration/AppConfiguration.swift

import Foundation

struct AppConfiguration: Codable, Equatable {
    static let defaultModel = "qwen2.5-coder:7b"
    static let defaultHost = "http://127.0.0.1:11434"
    static let defaultTemperature = 0.2

    var model: String
    var host: String
    var temperature: Double

    static let `default` = AppConfiguration(
        model: defaultModel,
        host: defaultHost,
        temperature: defaultTemperature
    )
}
