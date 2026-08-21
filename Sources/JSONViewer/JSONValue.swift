import Foundation

/// A JSON value that preserves object key order, unlike Foundation's JSONSerialization.
indirect enum JSONValue {
    case object([(key: String, value: JSONValue)])
    case array([JSONValue])
    case string(String)
    case number(String)
    case bool(Bool)
    case null
}

struct JSONParseError: Error, LocalizedError {
    let message: String
    let line: Int
    let column: Int

    var errorDescription: String? {
        "\(message) (line \(line), column \(column))"
    }
}

/// Minimal recursive-descent JSON parser that preserves object key order.
enum JSONParser {
    static func parse(_ text: String) throws -> JSONValue {
        var scanner = Scanner(text: text)
        scanner.skipWhitespace()
        let value = try scanner.parseValue()
        scanner.skipWhitespace()
        guard scanner.isAtEnd else {
            throw scanner.error("Unexpected trailing characters")
        }
        return value
    }

    private struct Scanner {
        let chars: [Character]
        var index: Int = 0
        var line: Int = 1
        var column: Int = 1

        init(text: String) {
            self.chars = Array(text)
        }

        var isAtEnd: Bool { index >= chars.count }

        func error(_ message: String) -> JSONParseError {
            JSONParseError(message: message, line: line, column: column)
        }

        mutating func advance() -> Character {
            let c = chars[index]
            index += 1
            if c == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            return c
        }

        func peek() -> Character? {
            isAtEnd ? nil : chars[index]
        }

        mutating func skipWhitespace() {
            while let c = peek(), c == " " || c == "\t" || c == "\n" || c == "\r" {
                _ = advance()
            }
        }

        mutating func expect(_ c: Character) throws {
            guard let p = peek(), p == c else {
                throw error("Expected '\(c)'")
            }
            _ = advance()
        }

        mutating func parseValue() throws -> JSONValue {
            skipWhitespace()
            guard let c = peek() else {
                throw error("Unexpected end of input")
            }
            switch c {
            case "{": return try parseObject()
            case "[": return try parseArray()
            case "\"": return .string(try parseString())
            case "t", "f": return try parseBool()
            case "n": return try parseNull()
            default: return try parseNumber()
            }
        }

        mutating func parseObject() throws -> JSONValue {
            try expect("{")
            skipWhitespace()
            var pairs: [(key: String, value: JSONValue)] = []
            if peek() == "}" {
                _ = advance()
                return .object(pairs)
            }
            while true {
                skipWhitespace()
                guard peek() == "\"" else {
                    throw error("Expected string key")
                }
                let key = try parseString()
                skipWhitespace()
                try expect(":")
                let value = try parseValue()
                pairs.append((key: key, value: value))
                skipWhitespace()
                guard let c = peek() else {
                    throw error("Unexpected end of input in object")
                }
                if c == "," {
                    _ = advance()
                    continue
                } else if c == "}" {
                    _ = advance()
                    break
                } else {
                    throw error("Expected ',' or '}'")
                }
            }
            return .object(pairs)
        }

        mutating func parseArray() throws -> JSONValue {
            try expect("[")
            skipWhitespace()
            var items: [JSONValue] = []
            if peek() == "]" {
                _ = advance()
                return .array(items)
            }
            while true {
                let value = try parseValue()
                items.append(value)
                skipWhitespace()
                guard let c = peek() else {
                    throw error("Unexpected end of input in array")
                }
                if c == "," {
                    _ = advance()
                    continue
                } else if c == "]" {
                    _ = advance()
                    break
                } else {
                    throw error("Expected ',' or ']'")
                }
            }
            return .array(items)
        }

        mutating func parseString() throws -> String {
            try expect("\"")
            var result = ""
            while true {
                guard let c = peek() else {
                    throw error("Unterminated string")
                }
                if c == "\"" {
                    _ = advance()
                    break
                }
                if c == "\\" {
                    _ = advance()
                    guard let esc = peek() else {
                        throw error("Unterminated escape sequence")
                    }
                    switch esc {
                    case "\"": result.append("\""); _ = advance()
                    case "\\": result.append("\\"); _ = advance()
                    case "/": result.append("/"); _ = advance()
                    case "b": result.append("\u{08}"); _ = advance()
                    case "f": result.append("\u{0C}"); _ = advance()
                    case "n": result.append("\n"); _ = advance()
                    case "r": result.append("\r"); _ = advance()
                    case "t": result.append("\t"); _ = advance()
                    case "u":
                        _ = advance()
                        let scalar = try parseUnicodeEscape()
                        result.unicodeScalars.append(scalar)
                    default:
                        throw error("Invalid escape sequence '\\\(esc)'")
                    }
                } else {
                    result.append(c)
                    _ = advance()
                }
            }
            return result
        }

        mutating func parseUnicodeEscape() throws -> Unicode.Scalar {
            guard index + 4 <= chars.count else {
                throw error("Invalid unicode escape")
            }
            var hex = ""
            for _ in 0..<4 {
                hex.append(advance())
            }
            guard let value = UInt32(hex, radix: 16), let scalar = Unicode.Scalar(value) else {
                throw error("Invalid unicode escape '\\u\(hex)'")
            }
            return scalar
        }

        mutating func parseBool() throws -> JSONValue {
            if matchLiteral("true") { return .bool(true) }
            if matchLiteral("false") { return .bool(false) }
            throw error("Invalid literal")
        }

        mutating func parseNull() throws -> JSONValue {
            if matchLiteral("null") { return .null }
            throw error("Invalid literal")
        }

        mutating func matchLiteral(_ literal: String) -> Bool {
            let litChars = Array(literal)
            guard index + litChars.count <= chars.count else { return false }
            for i in 0..<litChars.count {
                if chars[index + i] != litChars[i] { return false }
            }
            for _ in 0..<litChars.count { _ = advance() }
            return true
        }

        mutating func parseNumber() throws -> JSONValue {
            var text = ""
            if peek() == "-" { text.append(advance()) }
            guard let first = peek(), first.isNumber else {
                throw error("Invalid number")
            }
            while let c = peek(), c.isNumber { text.append(advance()) }
            if peek() == "." {
                text.append(advance())
                guard let d = peek(), d.isNumber else {
                    throw error("Invalid number: expected digit after '.'")
                }
                while let c = peek(), c.isNumber { text.append(advance()) }
            }
            if let e = peek(), e == "e" || e == "E" {
                text.append(advance())
                if let s = peek(), s == "+" || s == "-" { text.append(advance()) }
                guard let d = peek(), d.isNumber else {
                    throw error("Invalid number: expected digit in exponent")
                }
                while let c = peek(), c.isNumber { text.append(advance()) }
            }
            return .number(text)
        }
    }
}

extension JSONValue {
    /// Pretty-prints with 2-space indentation, preserving key order.
    func prettyPrinted(indent: Int = 0) -> String {
        let pad = String(repeating: "  ", count: indent)
        let childPad = String(repeating: "  ", count: indent + 1)
        switch self {
        case .object(let pairs):
            if pairs.isEmpty { return "{}" }
            let body = pairs.map { "\(childPad)\(Self.encodeString($0.key)): \($0.value.prettyPrinted(indent: indent + 1))" }
                .joined(separator: ",\n")
            return "{\n\(body)\n\(pad)}"
        case .array(let items):
            if items.isEmpty { return "[]" }
            let body = items.map { "\(childPad)\($0.prettyPrinted(indent: indent + 1))" }
                .joined(separator: ",\n")
            return "[\n\(body)\n\(pad)]"
        case .string(let s):
            return Self.encodeString(s)
        case .number(let n):
            return n
        case .bool(let b):
            return b ? "true" : "false"
        case .null:
            return "null"
        }
    }

    static func encodeString(_ s: String) -> String {
        var result = "\""
        for scalar in s.unicodeScalars {
            switch scalar {
            case "\"": result += "\\\""
            case "\\": result += "\\\\"
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default:
                if scalar.value < 0x20 {
                    result += String(format: "\\u%04x", scalar.value)
                } else {
                    result.unicodeScalars.append(scalar)
                }
            }
        }
        result += "\""
        return result
    }
}
