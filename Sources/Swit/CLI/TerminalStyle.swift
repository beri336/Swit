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
    enum Color: Int {
        // Standard colors
        case black = 30
        case red = 31
        case green = 32
        case yellow = 33
        case blue = 34
        case magenta = 35
        case cyan = 36
        case white = 37

        // Bright colors
        case gray = 90
        case brightRed = 91
        case brightGreen = 92
        case brightYellow = 93
        case brightBlue = 94
        case brightMagenta = 95
        case brightCyan = 96
        case brightWhite = 97
    }

    enum Attribute: Int {
        case reset = 0
        case bold = 1
        case dim = 2
        case italic = 3
        case underline = 4
        case blink = 5
        case inverse = 7
        case hidden = 8
        case strikethrough = 9
    }

    private static let escape = "\u{001B}["
    private static let reset = "\(escape)0m"

    static var supportsColor: Bool {
        #if os(Windows)
            return false
        #else
            let environment = ProcessInfo.processInfo.environment

            guard environment["TERM"] != "dumb" else {
                return false
            }

            if let noColor = environment["NO_COLOR"], !noColor.isEmpty {
                return false
            }

            return isatty(STDOUT_FILENO) != 0
        #endif
    }

    // MARK: - Combined styling
    static func styled(_ text: String,
                       foreground: Color? = nil,
                       background: Color? = nil,
                       attributes: [Attribute] = []
    ) -> String {
        var codes = attributes.map { String($0.rawValue) }

        if let foreground {
            codes.append(String(foreground.rawValue))
        }

        if let background {
            codes.append(String(background.rawValue + 10))
        }

        guard !codes.isEmpty else {
            return text
        }

        return apply(text, code: codes.joined(separator: ";"))
    }

    // MARK: - Text styles
    static func bold(_ text: String) -> String {
        styled(text, attributes: [.bold])
    }

    static func dim(_ text: String) -> String {
        styled(text, attributes: [.dim])
    }

    static func italic(_ text: String) -> String {
        styled(text, attributes: [.italic])
    }

    static func underline(_ text: String) -> String {
        styled(text, attributes: [.underline])
    }

    static func blink(_ text: String) -> String {
        styled(text, attributes: [.blink])
    }

    static func reversed(_ text: String) -> String {
        styled(text, attributes: [.inverse])
    }

    static func hidden(_ text: String) -> String {
        styled(text, attributes: [.hidden])
    }

    static func strikethrough(_ text: String) -> String {
        styled(text, attributes: [.strikethrough])
    }

    // MARK: - Standard colors
    static func black(_ text: String) -> String {
        styled(text, foreground: .black)
    }

    static func red(_ text: String) -> String {
        styled(text, foreground: .red)
    }

    static func green(_ text: String) -> String {
        styled(text, foreground: .green)
    }

    static func yellow(_ text: String) -> String {
        styled(text, foreground: .yellow)
    }

    static func blue(_ text: String) -> String {
        styled(text, foreground: .blue)
    }

    static func magenta(_ text: String) -> String {
        styled(text, foreground: .magenta)
    }

    static func cyan(_ text: String) -> String {
        styled(text, foreground: .cyan)
    }

    static func white(_ text: String) -> String {
        styled(text, foreground: .white)
    }

    // MARK: - Bright colors
    static func gray(_ text: String) -> String {
        styled(text, foreground: .gray)
    }

    static func brightRed(_ text: String) -> String {
        styled(text, foreground: .brightRed)
    }

    static func brightGreen(_ text: String) -> String {
        styled(text, foreground: .brightGreen)
    }

    static func brightYellow(_ text: String) -> String {
        styled(text, foreground: .brightYellow)
    }

    static func brightBlue(_ text: String) -> String {
        styled(text, foreground: .brightBlue)
    }

    static func brightMagenta(_ text: String) -> String {
        styled(text, foreground: .brightMagenta)
    }

    static func brightCyan(_ text: String) -> String {
        styled(text, foreground: .brightCyan)
    }

    static func brightWhite(_ text: String) -> String {
        styled(text, foreground: .brightWhite)
    }

    // MARK: - Custom colors
    static func rgb(_ text: String,
                    red: UInt8,
                    green: UInt8,
                    blue: UInt8
    ) -> String {
        apply(text, code: "38;2;\(red);\(green);\(blue)")
    }

    static func backgroundRGB(_ text: String,
                              red: UInt8,
                              green: UInt8,
                              blue: UInt8
    ) -> String {
        apply(text, code: "48;2;\(red);\(green);\(blue)")
    }

    static func palette(_ text: String,
                        index: UInt8) -> String {
        apply(text, code: "38;5;\(index)")
    }

    // MARK: - Internal formatting
    private static func apply(_ text: String,
                              code: String) -> String {
        guard supportsColor else {
            return text
        }

        return "\(escape)\(code)m\(text)\(reset)"
    }
}
