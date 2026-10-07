import SwiftData
import SwiftUI

@main
struct InvoiceLensApp: App {
    private let container = InvoiceLensApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            InvoiceListView()
        }
        .modelContainer(container)
    }

    private static func makeContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(for: Invoice.self)
            #if DEBUG
            // Launch argument used for demos and screenshots: fills an empty store.
            if ProcessInfo.processInfo.arguments.contains("-seed-sample-data") {
                let context = container.mainContext
                if (try? context.fetchCount(FetchDescriptor<Invoice>())) == 0 {
                    Invoice.samples().forEach(context.insert)
                    try? context.save()
                }
            }
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
