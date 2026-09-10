// Sources/Swit/Configuration/ConfigurationValidator.swift

import Foundation

enum ConfigurationValidator {
    static let minimumTemperature = 0.0
    static let maximumTemperature = 2.0

    static func isValid(temperature: Double) -> Bool {
        temperature.isFinite && temperature >= minimumTemperature
            && temperature <= maximumTemperature
    }

    static func isValid(contextWindow: Int) -> Bool {
        contextWindow > 0
    }

    static func isValid(keepAlive: String) -> Bool {
        let value = keepAlive.trimmingCharacters(in: .whitespacesAndNewlines)

        if value == "0" || value == "-1" {
            return true
        }

        let pattern = #"^[1-9]\d*[smhd]$"#

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }
}
