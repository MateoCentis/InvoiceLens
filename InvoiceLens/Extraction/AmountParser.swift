import Foundation

/// Parses money amounts as printed on invoices, in both "12.345,67" (Argentina)
/// and "12,345.67" styles. The last separator followed by 1–2 digits is the decimal one.
nonisolated enum AmountParser {
    static func parse(_ raw: String) -> Decimal? {
        let cleaned = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard cleaned.contains(where: \.isNumber) else { return nil }

        let separators: Set<Character> = [".", ","]
        if let lastSeparator = cleaned.lastIndex(where: separators.contains) {
            let fraction = cleaned[cleaned.index(after: lastSeparator)...]
            if (1...2).contains(fraction.count) {
                let integer = cleaned[..<lastSeparator].filter(\.isNumber)
                return Decimal(string: "\(integer.isEmpty ? "0" : integer).\(fraction)")
            }
        }
        // No decimal part: every separator is a thousands separator.
        return Decimal(string: cleaned.filter(\.isNumber))
    }
}
