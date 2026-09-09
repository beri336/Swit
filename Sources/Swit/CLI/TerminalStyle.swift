// Sources/Swit/CLI/TerminalStyle.swift

import Foundation

#if !os(Windows)
    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #elseif canImport(Musl)
        import Musl
    #endif
#endif

enum TerminalStyle {
    private static let escape = "\u{001B}["
    private static let reset = "\(escape)0m"

    static var supportsColor: Bool {
        #if os(Windows)
            return false
        #else
            return isatty(fileno(stdout)) != 0
        #endif
    }

    static func bold(_ text: String) -> String {
        apply(text, code: "1")
    }

    static func dim(_ text: String) -> String {
        apply(text, code: "2")
    }

    static func cyan(_ text: String) -> String {
        apply(text, code: "36")
    }

    static func green(_ text: String) -> String {
        apply(text, code: "32")
    }

    static func yellow(_ text: String) -> String {
        apply(text, code: "33")
    }

    static func red(_ text: String) -> String {
        apply(text, code: "31")
    }

    private static func apply(_ text: String, code: String) -> String {
        guard supportsColor else {
            return text
        }

        return "\(escape)\(code)m\(text)\(reset)"
    }
}
