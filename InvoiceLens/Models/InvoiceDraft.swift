import Foundation

/// The editable result of extraction, reviewed by the user before it becomes an `Invoice`.
nonisolated struct InvoiceDraft: Equatable, Sendable {
    var supplierName = ""
    var supplierTaxID = ""
    var invoiceType: InvoiceType = .other
    var invoiceNumber = ""
    var issueDate: Date?
    var total: Decimal = 0
    var taxAmount: Decimal = 0
    var currencyCode = "ARS"

    /// Keeps this draft's values and fills the empty ones from `other`.
    func fillingGaps(from other: InvoiceDraft) -> InvoiceDraft {
        var result = self
        if result.supplierName.isEmpty { result.supplierName = other.supplierName }
        if !CUIT.isValid(result.supplierTaxID), CUIT.isValid(other.supplierTaxID) {
            result.supplierTaxID = other.supplierTaxID
        }
        if result.invoiceType == .other { result.invoiceType = other.invoiceType }
        if result.invoiceNumber.isEmpty { result.invoiceNumber = other.invoiceNumber }
        if result.issueDate == nil { result.issueDate = other.issueDate }
        if result.total == 0 { result.total = other.total }
        if result.taxAmount == 0 { result.taxAmount = other.taxAmount }
        return result
    }
}

nonisolated enum InvoiceType: String, CaseIterable, Identifiable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"
    case ticket = "Ticket"
    case other = "Other"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .a, .b, .c: "Factura \(rawValue)"
        case .ticket: "Ticket"
        case .other: "Other"
        }
    }
}

nonisolated enum ExtractionMethod: String, Sendable {
    case appleIntelligence
    case rules

    var title: String {
        switch self {
        case .appleIntelligence: "Apple Intelligence"
        case .rules: "Text rules"
        }
    }
}
