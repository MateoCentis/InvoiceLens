import SwiftData
import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmingDelete = false

    var body: some View {
        List {
            if let data = invoice.imageData, let image = UIImage(data: data) {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Invoice photo")
                }
            }

            Section("Supplier") {
                LabeledContent("Name", value: invoice.supplierName)
                LabeledContent("CUIT", value: invoice.supplierTaxID.isEmpty ? "—" : invoice.supplierTaxID)
            }

            Section("Invoice") {
                LabeledContent("Type", value: invoice.invoiceType.title)
                LabeledContent("Number", value: invoice.invoiceNumber.isEmpty ? "—" : invoice.invoiceNumber)
                LabeledContent("Issued") {
                    Text(invoice.issueDate, format: .dateTime.day().month().year())
                }
            }

            Section("Amounts") {
                LabeledContent("Total") {
                    Text(invoice.total, format: .currency(code: invoice.currencyCode))
                        .fontWeight(.semibold)
                }
                LabeledContent("VAT (IVA)") {
                    Text(invoice.taxAmount, format: .currency(code: invoice.currencyCode))
                }
            }

            Section {
                LabeledContent("Extracted with", value: invoice.extractionMethod.title)
                DisclosureGroup("Recognized text") {
                    Text(invoice.recognizedText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }

            Section {
                Button("Delete Invoice", role: .destructive) {
                    isConfirmingDelete = true
                }
            }
        }
        .navigationTitle(invoice.supplierName.isEmpty ? "Invoice" : invoice.supplierName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this invoice?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(invoice)
                dismiss()
            }
        }
    }
}
