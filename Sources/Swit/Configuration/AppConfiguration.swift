// Sources/Swit/Configuration/AppConfiguration.swift

import Foundation

struct AppConfiguration: Codable, Equatable {
    static let defaultModel = "qwen2.5-coder:7b"
    static let defaultHost = "http://127.0.0.1:11434"
    static let defaultTemperature = 0.2
    static let defaultContextWindow = 8_192
    static let defaultKeepAlive = "5m"

    var model: String
    var host: String
    var temperature: Double
    var contextWindow: Int
    var keepAlive: String

    static let `default` = AppConfiguration(
        model: defaultModel,
        host: defaultHost,
        temperature: defaultTemperature,
        contextWindow: defaultContextWindow,
        keepAlive: defaultKeepAlive
    )

    private enum CodingKeys: String, CodingKey {
        case model
        case host
        case temperature
        case contextWindow
        case keepAlive
    }

    init(model: String,
         host: String,
         temperature: Double,
         contextWindow: Int,
         keepAlive: String)
    {
        self.model = model
        self.host = host
        self.temperature = temperature
        self.contextWindow = contextWindow
        self.keepAlive = keepAlive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        model = try container.decodeIfPresent(String.self, forKey: .model) ??
            Self.defaultModel
        host = try container.decodeIfPresent(String.self, forKey: .host) ??
            Self.defaultHost
        temperature = try container.decodeIfPresent(Double.self, forKey: .temperature) ??
            Self.defaultTemperature
        contextWindow = try container.decodeIfPresent(Int.self, forKey: .contextWindow) ??
            Self.defaultContextWindow
        keepAlive = try container.decodeIfPresent(String.self, forKey: .keepAlive) ??
            Self.defaultKeepAlive
    }
}
