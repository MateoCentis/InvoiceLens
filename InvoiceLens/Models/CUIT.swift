import Foundation

/// Argentine tax ID (CUIT/CUIL): 11 digits, the last one a mod-11 check digit.
nonisolated enum CUIT {
    private static let weights = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2]

    static func digits(of value: String) -> [Int]? {
        let digits = value.compactMap(\.wholeNumberValue)
        return digits.count == 11 ? digits : nil
    }

    static func isValid(_ value: String) -> Bool {
        guard let digits = digits(of: value) else { return false }
        let sum = zip(digits, weights).map(*).reduce(0, +)
        let remainder = 11 - sum % 11
        let expected = switch remainder {
        case 11: 0
        case 10: 9
        default: remainder
        }
        return digits[10] == expected
    }

    /// "30712345671" → "30-71234567-1". Returns the input unchanged if it isn't 11 digits.
    static func formatted(_ value: String) -> String {
        guard let digits = digits(of: value) else { return value }
        let string = digits.map(String.init).joined()
        return "\(string.prefix(2))-\(string.dropFirst(2).prefix(8))-\(string.suffix(1))"
    }
}
