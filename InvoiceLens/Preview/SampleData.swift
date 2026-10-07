import Foundation
import SwiftData

extension InvoiceDraft {
    static var sample: InvoiceDraft {
        var draft = InvoiceDraft()
        draft.supplierName = "Farmacia del Centro S.R.L."
        draft.supplierTaxID = "30-71234567-1"
        draft.invoiceType = .b
        draft.invoiceNumber = "0003-00012345"
        draft.issueDate = .now
        draft.total = Decimal(string: "12250.50") ?? 0
        draft.taxAmount = Decimal(string: "2126.12") ?? 0
        return draft
    }
}

extension Invoice {
    /// Demo invoices spread over recent months, for previews and the seed launch argument.
    static func samples(now: Date = .now, calendar: Calendar = .current) -> [Invoice] {
        let suppliers: [(String, String, InvoiceType, String)] = [
            ("Farmacia del Centro S.R.L.", "30-71234567-1", .b, "12250.50"),
            ("Distribuidora Litoral S.A.", "20-12345678-6", .a, "84300.00"),
            ("Panadería La Espiga", "", .c, "6800.00"),
            ("Ferretería San Martín", "30-71234567-1", .b, "23990.90"),
            ("Supermercado El Sol", "", .ticket, "41520.35"),
            ("Distribuidora Litoral S.A.", "20-12345678-6", .a, "67150.00"),
        ]
        return suppliers.enumerated().map { index, supplier in
            var draft = InvoiceDraft()
            draft.supplierName = supplier.0
            draft.supplierTaxID = supplier.1
            draft.invoiceType = supplier.2
            draft.invoiceNumber = String(format: "0001-%08d", 1_200 + index)
            draft.issueDate = calendar.date(byAdding: .day, value: -index * 17, to: now)
            draft.total = Decimal(string: supplier.3) ?? 0
            draft.taxAmount = supplier.2 == .a ? draft.total * Decimal(string: "0.21")! / Decimal(string: "1.21")! : 0
            return Invoice(draft: draft, method: .rules, recognizedText: "", imageData: nil)
        }
    }
}

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(for: Invoice.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            Invoice.samples().forEach(container.mainContext.insert)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }
}
