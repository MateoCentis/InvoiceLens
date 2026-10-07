import Foundation

/// Extracts invoice fields from OCR lines with patterns typical of Argentine invoices.
/// Works on every device, and fills gaps the language model leaves.
nonisolated enum RuleBasedInvoiceExtractor {
    static func extract(from lines: [String], calendar: Calendar = .current) -> InvoiceDraft {
        let text = lines.joined(separator: "\n")
        var draft = InvoiceDraft()
        draft.supplierName = supplierName(in: lines)
        draft.supplierTaxID = firstValidCUIT(in: text) ?? ""
        draft.invoiceType = invoiceType(in: lines)
        draft.invoiceNumber = invoiceNumber(in: text) ?? ""
        draft.issueDate = issueDate(in: text, calendar: calendar)
        draft.total = total(in: lines) ?? 0
        draft.taxAmount = taxAmount(in: lines) ?? 0
        return draft
    }

    // MARK: - Fields

    static func supplierName(in lines: [String]) -> String {
        let legalName = /raz[oó]n\s+social\s*:?\s*(.+)/.ignoresCase()
        for line in lines {
            if let match = line.firstMatch(of: legalName) {
                return String(match.1).trimmingCharacters(in: .whitespaces)
            }
        }
        // Otherwise the business name is usually the first line with real words.
        let skipped = ["original", "duplicado", "triplicado", "factura", "ticket", "cod.", "recibo"]
        return lines.first { line in
            let lowercased = line.lowercased()
            return line.filter(\.isLetter).count >= 3
                && !line.contains(":")
                && !skipped.contains { lowercased.contains($0) }
        }?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    static func firstValidCUIT(in text: String) -> String? {
        for match in text.matches(of: /\b(\d{2})-?(\d{8})-?(\d)\b/) {
            let candidate = "\(match.1)\(match.2)\(match.3)"
            if CUIT.isValid(candidate) {
                return CUIT.formatted(candidate)
            }
        }
        return nil
    }

    static func invoiceType(in lines: [String]) -> InvoiceType {
        for line in lines {
            if let match = line.firstMatch(of: /factura\s+([abc])\b/.ignoresCase()) {
                return InvoiceType(rawValue: match.1.uppercased()) ?? .other
            }
        }
        // The big letter box at the top of the invoice, OCR'd as a line on its own.
        if let letter = lines.first(where: { ["A", "B", "C"].contains($0.trimmingCharacters(in: .whitespaces)) }) {
            return InvoiceType(rawValue: letter.trimmingCharacters(in: .whitespaces)) ?? .other
        }
        if lines.contains(where: { $0.localizedCaseInsensitiveContains("ticket") }) {
            return .ticket
        }
        return .other
    }

    static func invoiceNumber(in text: String) -> String? {
        if let match = text.firstMatch(of: /\b(\d{4,5})\s*-\s*(\d{8})\b/) {
            return "\(match.1)-\(match.2)"
        }
        let labeled = /punto\s+de\s+venta\s*:?\s*(\d{1,5}).*?n(?:ro|°|º)\.?\s*:?\s*(\d{1,8})/
            .ignoresCase()
        if let match = text.firstMatch(of: labeled) {
            return "\(padded(match.1, to: 4))-\(padded(match.2, to: 8))"
        }
        return nil
    }

    static func issueDate(in text: String, calendar: Calendar) -> Date? {
        let labeled = /fecha(?:\s+de\s+emisi[oó]n)?\s*:?\s*(\d{1,2})\/(\d{1,2})\/(\d{4})/.ignoresCase()
        let match = text.firstMatch(of: labeled)?.output ?? text.firstMatch(of: /(\d{1,2})\/(\d{1,2})\/(\d{4})/)
            .map { ($0.0, $0.1, $0.2, $0.3) }
        guard let (_, day, month, year) = match,
              let day = Int(day), let month = Int(month), let year = Int(year)
        else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func total(in lines: [String]) -> Decimal? {
        var candidates: [Decimal] = []
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            guard lowercased.contains("total"), !lowercased.contains("subtotal") else { continue }
            // The amount may sit on the same line or, in two-column layouts, the next one.
            let amounts = amounts(in: line)
            if let last = amounts.last {
                candidates.append(last)
            } else if index + 1 < lines.count, let next = self.amounts(in: lines[index + 1]).last {
                candidates.append(next)
            }
        }
        return candidates.max()
    }

    static func taxAmount(in lines: [String]) -> Decimal? {
        lines
            .filter { $0.localizedCaseInsensitiveContains("iva") && $0.contains("$") }
            .compactMap { amounts(in: $0).last }
            .first
    }

    // MARK: - Helpers

    /// Money amounts in a line. When the line uses "$", only amounts after it count,
    /// which skips quantities and percentages like "IVA 21%".
    static func amounts(in line: String) -> [Decimal] {
        if line.contains("$") {
            return line.matches(of: /\$\s*([\d.,]*\d)/).compactMap { AmountParser.parse(String($0.1)) }
        }
        return line.matches(of: /(\d[\d.,]*)(%?)/).compactMap { match in
            guard match.2.isEmpty else { return nil } // a percentage
            let token = String(match.1).trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
            // Plain integers are quantities or reference numbers, not money.
            guard token.contains(where: { $0 == "." || $0 == "," }) else { return nil }
            return AmountParser.parse(token)
        }
    }

    private static func padded(_ digits: Substring, to length: Int) -> String {
        String(repeating: "0", count: max(0, length - digits.count)) + digits
    }
}
