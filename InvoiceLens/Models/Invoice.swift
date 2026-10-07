import Foundation
import SwiftData

/// A saved invoice. The original image is kept outside the database file.
@Model
final class Invoice {
    var supplierName: String
    var supplierTaxID: String
    var invoiceTypeRaw: String
    var invoiceNumber: String
    var issueDate: Date
    var total: Decimal
    var taxAmount: Decimal
    var currencyCode: String
    var extractionMethodRaw: String
    var recognizedText: String
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date

    init(draft: InvoiceDraft, method: ExtractionMethod, recognizedText: String, imageData: Data?, createdAt: Date = .now) {
        supplierName = draft.supplierName
        supplierTaxID = draft.supplierTaxID
        invoiceTypeRaw = draft.invoiceType.rawValue
        invoiceNumber = draft.invoiceNumber
        issueDate = draft.issueDate ?? createdAt
        total = draft.total
        taxAmount = draft.taxAmount
        currencyCode = draft.currencyCode
        extractionMethodRaw = method.rawValue
        self.recognizedText = recognizedText
        self.imageData = imageData
        self.createdAt = createdAt
    }

    var invoiceType: InvoiceType {
        InvoiceType(rawValue: invoiceTypeRaw) ?? .other
    }

    var extractionMethod: ExtractionMethod {
        ExtractionMethod(rawValue: extractionMethodRaw) ?? .rules
    }
}
