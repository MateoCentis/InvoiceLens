import SwiftData
import SwiftUI

/// Shows what was extracted so the user can correct it before saving.
/// Extraction is never 100% reliable, so a human always confirms.
struct InvoiceReviewView: View {
    let pending: PendingInvoice

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var draft: InvoiceDraft

    init(pending: PendingInvoice) {
        self.pending = pending
        _draft = State(initialValue: pending.draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Extracted with \(pending.method.title). Please check the values.", systemImage: methodSymbol)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let data = pending.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Invoice photo")
                    }
                }

                InvoiceFieldsSection(draft: $draft)

                Section {
                    DisclosureGroup("Recognized text") {
                        Text(pending.recognizedText)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Review Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(draft.total <= 0)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var methodSymbol: String {
        pending.method == .appleIntelligence ? "apple.intelligence" : "text.viewfinder"
    }

    private func save() {
        modelContext.insert(
            Invoice(draft: draft, method: pending.method, recognizedText: pending.recognizedText, imageData: pending.imageData)
        )
        dismiss()
    }
}

/// Editable invoice fields, shared by review and detail screens.
struct InvoiceFieldsSection: View {
    @Binding var draft: InvoiceDraft

    var body: some View {
        Section("Supplier") {
            TextField("Name", text: $draft.supplierName)
            HStack {
                TextField("CUIT", text: $draft.supplierTaxID)
                    .keyboardType(.numbersAndPunctuation)
                if !draft.supplierTaxID.isEmpty {
                    Image(systemName: CUIT.isValid(draft.supplierTaxID) ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(CUIT.isValid(draft.supplierTaxID) ? .green : .orange)
                        .accessibilityLabel(CUIT.isValid(draft.supplierTaxID) ? "Valid CUIT" : "CUIT check digit doesn't match")
                }
            }
        }

        Section("Invoice") {
            Picker("Type", selection: $draft.invoiceType) {
                ForEach(InvoiceType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }
            TextField("Number (0001-00001234)", text: $draft.invoiceNumber)
            DatePicker("Issued", selection: issueDate, displayedComponents: .date)
        }

        Section("Amounts") {
            LabeledContent("Total") {
                TextField("Total", value: $draft.total, format: .currency(code: draft.currencyCode))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            LabeledContent("VAT (IVA)") {
                TextField("VAT", value: $draft.taxAmount, format: .currency(code: draft.currencyCode))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private var issueDate: Binding<Date> {
        Binding { draft.issueDate ?? .now } set: { draft.issueDate = $0 }
    }
}

#Preview {
    InvoiceReviewView(
        pending: PendingInvoice(imageData: nil, recognizedText: "FACTURA B\nTOTAL: $ 12.250,50", draft: .sample, method: .rules)
    )
    .modelContainer(.preview)
}
