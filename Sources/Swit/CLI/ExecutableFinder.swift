// Sources/Swit/CLI/ExecutableFinder.swift

import Foundation

enum ExecutableFinder {
    static func find(_ name: String) -> String? {
        let environment = ProcessInfo.processInfo.environment
        let pathValue = environment["PATH"] ?? environment["Path"] ?? ""
        #if os(Windows)
        let separator: Character = ";"
        let names = name.lowercased().hasSuffix(".exe") ? [name] : [name, "\(name).exe"]
        #else
        let separator: Character = ":"
        let names = [name]
        #endif

        let fileManager = FileManager.default
        for directory in pathValue.split(separator: separator) {
            let dir = String(directory).trimmingCharacters(in: .whitespaces)
            guard !dir.isEmpty else { continue }
            for candidate in names {
                let fullPath = URL(fileURLWithPath: dir).appendingPathComponent(candidate).path
                if fileManager.fileExists(atPath: fullPath) {
                    return fullPath
                }
            }
        }
        return nil
    }
}
