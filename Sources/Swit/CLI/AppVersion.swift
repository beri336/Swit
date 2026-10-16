// src/Swit/CLI/AppVersion.swift

struct AppVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    init?(_ value: String) {
        let parts = value.split(
            separator: ".",
            omittingEmptySubsequences: false)

        guard parts.count == 3 else {
            return nil
        }

        var numbers: [Int] = []

        for part in parts {
            guard !part.isEmpty,
                part.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }),
                part.count == 1 || part.first != "0",
                let number = Int(part)
            else {
                return nil
            }

            numbers.append(number)
        }

        major = numbers[0]
        minor = numbers[1]
        patch = numbers[2]
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }

        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }

        return lhs.patch < rhs.patch
    }
}
