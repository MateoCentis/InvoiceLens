import SwiftUI

struct InvoiceRow: View {
    let invoice: Invoice

    var body: some View {
        HStack(spacing: 12) {
            Text(invoice.invoiceType == .other ? "?" : String(invoice.invoiceType.rawValue.prefix(1)))
                .font(.headline.monospaced())
                .frame(width: 36, height: 36)
                .background(.tint.opacity(0.15), in: .rect(cornerRadius: 8))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(invoice.supplierName.isEmpty ? "Unknown supplier" : invoice.supplierName)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(invoice.total, format: .currency(code: invoice.currencyCode))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(invoice.issueDate, format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        invoice.invoiceNumber.isEmpty ? invoice.invoiceType.title : "\(invoice.invoiceType.title) · \(invoice.invoiceNumber)"
    }
}
