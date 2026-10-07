import PhotosUI
import SwiftData
import SwiftUI

struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Invoice.issueDate, order: .reverse) private var invoices: [Invoice]

    @State private var importer = InvoiceImporter()
    @State private var searchText = ""
    @State private var isShowingPhotoPicker = false
    @State private var isShowingDocumentScanner = false
    @State private var pickedPhoto: PhotosPickerItem?

    private var filteredInvoices: [Invoice] {
        guard !searchText.isEmpty else { return invoices }
        return invoices.filter {
            $0.supplierName.localizedStandardContains(searchText)
                || $0.invoiceNumber.contains(searchText)
                || $0.supplierTaxID.contains(searchText)
        }
    }

    private var months: [(month: Date, invoices: [Invoice])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredInvoices) {
            calendar.dateInterval(of: .month, for: $0.issueDate)?.start ?? $0.issueDate
        }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0] ?? []) }
    }

    private func total(of invoices: [Invoice]) -> Decimal {
        invoices.reduce(Decimal.zero) { $0 + $1.total }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty, !invoices.isEmpty {
                    Section {
                        SpendingChart(invoices: invoices)
                    }
                }
                ForEach(months, id: \.month) { group in
                    Section {
                        ForEach(group.invoices) { invoice in
                            NavigationLink(value: invoice) {
                                InvoiceRow(invoice: invoice)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { group.invoices[$0] }.forEach(modelContext.delete)
                        }
                    } header: {
                        HStack {
                            Text(group.month, format: .dateTime.month(.wide).year())
                            Spacer()
                            Text(total(of: group.invoices), format: .currency(code: "ARS"))
                        }
                    }
                }
            }
            .overlay {
                if invoices.isEmpty {
                    ContentUnavailableView {
                        Label("No Invoices Yet", systemImage: "doc.text.viewfinder")
                    } description: {
                        Text("Scan a paper invoice or pick a photo. Text is read and extracted on your device.")
                    }
                } else if filteredInvoices.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .overlay {
                if let message = importer.stage.message, importer.isWorking {
                    ProgressView(message)
                        .padding(24)
                        .glassEffect(in: .rect(cornerRadius: 20))
                }
            }
            .navigationTitle("Invoices")
            .navigationDestination(for: Invoice.self) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .searchable(text: $searchText, prompt: "Supplier, number or CUIT")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Scan Document", systemImage: "doc.viewfinder") {
                            isShowingDocumentScanner = true
                        }
                        .disabled(!DocumentScannerView.isAvailable)
                        Button("Choose Photo", systemImage: "photo") {
                            isShowingPhotoPicker = true
                        }
                    } label: {
                        Label("Add Invoice", systemImage: "plus")
                    }
                    .disabled(importer.isWorking)
                }
            }
            .photosPicker(isPresented: $isShowingPhotoPicker, selection: $pickedPhoto, matching: .images)
            .onChange(of: pickedPhoto) { _, item in
                guard let item else { return }
                pickedPhoto = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await importer.process(imageData: data)
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingDocumentScanner) {
                DocumentScannerView { data in
                    isShowingDocumentScanner = false
                    Task { await importer.process(imageData: data) }
                } onCancel: {
                    isShowingDocumentScanner = false
                }
                .ignoresSafeArea()
            }
            .sheet(item: $importer.pending) { pending in
                InvoiceReviewView(pending: pending)
            }
            .alert(
                "Import Failed",
                isPresented: Binding(
                    get: { if case .failed = importer.stage { true } else { false } },
                    set: { if !$0 { importer.dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importer.stage.message ?? "")
            }
        }
    }
}

#Preview {
    InvoiceListView()
        .modelContainer(.preview)
}

#Preview("Empty") {
    InvoiceListView()
        .modelContainer(for: Invoice.self, inMemory: true)
}
