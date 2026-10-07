import Foundation
import FoundationModels

/// Extracts invoice fields with Apple's on-device language model (Apple Intelligence).
/// Guided generation (`@Generable`) makes the model return this exact Swift type,
/// so there is no JSON to parse and no malformed output to handle.
nonisolated struct FoundationModelsInvoiceExtractor {
    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    private static let instructions = """
        You extract data from Argentine invoices (facturas). The text comes from OCR and may \
        contain recognition errors. In the source, amounts use "." for thousands and "," for decimals. \
        Never invent values: use an empty string or 0 when a field is not present.
        """

    func extract(from lines: [String]) async throws -> InvoiceDraft {
        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(
            to: "Invoice text:\n" + lines.joined(separator: "\n"),
            generating: ExtractedInvoice.self
        )
        return response.content.draft()
    }
}

@Generable
nonisolated struct ExtractedInvoice {
    @Guide(description: "Legal or trade name of the business that issued the invoice")
    var supplierName: String

    @Guide(description: "CUIT tax ID of the issuer, formatted as XX-XXXXXXXX-X, or empty")
    var supplierTaxID: String

    @Guide(description: "Invoice letter", .anyOf(["A", "B", "C", "Ticket", "Other"]))
    var invoiceType: String

    @Guide(description: "Point of sale and invoice number, formatted as 0001-00001234, or empty")
    var invoiceNumber: String

    @Guide(description: "Issue date formatted as YYYY-MM-DD, or empty")
    var issueDate: String

    @Guide(description: "Grand total payable, as a plain number with a dot for decimals")
    var total: Double

    @Guide(description: "Total VAT (IVA) amount, or 0 if not shown")
    var taxAmount: Double

    func draft(calendar: Calendar = .current) -> InvoiceDraft {
        var draft = InvoiceDraft()
        draft.supplierName = supplierName.trimmingCharacters(in: .whitespaces)
        draft.supplierTaxID = CUIT.formatted(supplierTaxID)
        draft.invoiceType = InvoiceType(rawValue: invoiceType) ?? .other
        draft.invoiceNumber = invoiceNumber
        draft.issueDate = Self.date(from: issueDate, calendar: calendar)
        draft.total = Self.decimal(total)
        draft.taxAmount = Self.decimal(taxAmount)
        return draft
    }

    private static func date(from string: String, calendar: Calendar) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// Goes through a rounded string so binary floating point noise doesn't reach the money value.
    private static func decimal(_ value: Double) -> Decimal {
        Decimal(string: String(format: "%.2f", value)) ?? 0
    }
}
