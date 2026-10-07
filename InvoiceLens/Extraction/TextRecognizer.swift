import Foundation
import Vision

/// On-device OCR with the Vision framework.
nonisolated enum TextRecognizer {
    /// Recognized lines of text, in reading order and cleaned up for extraction.
    static func lines(in imageData: Data) async throws -> [String] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "es-AR"), Locale.Language(identifier: "en-US")]
        request.usesLanguageCorrection = true
        let observations = try await request.perform(on: imageData)
        return observations.compactMap { $0.topCandidates(1).first?.string }.map(normalized)
    }

    /// Fixes common OCR artifacts: "12.250, 50" → "12.250,50" and "30 - 71234567 - 1" → "30-71234567-1".
    static func normalized(_ line: String) -> String {
        line
            .replacing(/(\d)([.,])\s+(\d)/) { "\($0.1)\($0.2)\($0.3)" }
            .replacing(/(\d)\s+-\s+(\d)/) { "\($0.1)-\($0.2)" }
    }
}
