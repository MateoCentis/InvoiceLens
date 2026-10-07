import Foundation
import OSLog

/// Chooses the best available extractor: the on-device model when present, then
/// text rules to fill whatever it missed (or for everything, on devices without it).
nonisolated enum InvoiceExtractionService {
    private static let logger = Logger(subsystem: "dev.mateo.InvoiceLens", category: "Extraction")

    static func extract(from lines: [String]) async -> (draft: InvoiceDraft, method: ExtractionMethod) {
        let ruleBased = RuleBasedInvoiceExtractor.extract(from: lines)
        guard FoundationModelsInvoiceExtractor.isAvailable else {
            return (ruleBased, .rules)
        }
        do {
            let modelDraft = try await FoundationModelsInvoiceExtractor().extract(from: lines)
            return (modelDraft.fillingGaps(from: ruleBased), .appleIntelligence)
        } catch {
            logger.error("Model extraction failed, using rules: \(error)")
            return (ruleBased, .rules)
        }
    }
}
