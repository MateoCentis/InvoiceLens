import Foundation
import Observation

/// An imported invoice waiting for the user to review it.
struct PendingInvoice: Identifiable {
    let id = UUID()
    let imageData: Data?
    let recognizedText: String
    var draft: InvoiceDraft
    let method: ExtractionMethod
}

/// Runs the import pipeline: image → OCR → extraction → review.
/// `@Observable` makes SwiftUI re-render any view that reads `stage` or `pending` when they change.
@Observable
final class InvoiceImporter {
    enum Stage: Equatable {
        case idle
        case readingText
        case extracting(usingModel: Bool)
        case failed(String)

        var message: String? {
            switch self {
            case .idle: nil
            case .readingText: "Reading text…"
            case .extracting(let usingModel): usingModel ? "Extracting with Apple Intelligence…" : "Extracting details…"
            case .failed(let message): message
            }
        }
    }

    private(set) var stage: Stage = .idle
    var pending: PendingInvoice?

    var isWorking: Bool {
        switch stage {
        case .readingText, .extracting: true
        case .idle, .failed: false
        }
    }

    func process(imageData: Data) async {
        stage = .readingText
        do {
            let image = ImageCompressor.jpegData(from: imageData) ?? imageData
            let lines = try await TextRecognizer.lines(in: image)
            guard !lines.isEmpty else {
                stage = .failed("No text found in that image.")
                return
            }
            stage = .extracting(usingModel: FoundationModelsInvoiceExtractor.isAvailable)
            let result = await InvoiceExtractionService.extract(from: lines)
            pending = PendingInvoice(
                imageData: image,
                recognizedText: lines.joined(separator: "\n"),
                draft: result.draft,
                method: result.method
            )
            stage = .idle
        } catch {
            stage = .failed("Couldn't read the image: \(error.localizedDescription)")
        }
    }

    func dismissError() {
        stage = .idle
    }
}
