// Sources/Swit/Commit/StagingMode.swift

import ArgumentParser

enum StagingMode: String, CaseIterable, ExpressibleByArgument {
    case stagedOnly
    case tracked
    case all

    init?(argument: String) {
        switch argument.lowercased() {
            case "staged", "staged-only":
                self = .stagedOnly
            case "tracked":
                self = .tracked
            case "all":
                self = .all
            default:
                return nil
        }
    }
}