import Foundation
import Testing
import UIKit
@testable import InvoiceLens

struct TextRecognizerTests {
    /// Renders text lines into a PNG, like a clean scan.
    private func image(of lines: [String]) -> Data {
        let font = UIFont.monospacedSystemFont(ofSize: 28, weight: .regular)
        let size = CGSize(width: 1_000, height: CGFloat(lines.count) * 44 + 80)
        return UIGraphicsImageRenderer(size: size).pngData { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            for (index, line) in lines.enumerated() {
                (line as NSString).draw(
                    at: CGPoint(x: 40, y: 40 + CGFloat(index) * 44),
                    withAttributes: [.font: font, .foregroundColor: UIColor.black]
                )
            }
        }
    }

    @Test func recognizesInvoiceText() async throws {
        let lines = try await TextRecognizer.lines(in: image(of: ["FACTURA B", "CUIT: 30-71234567-1", "TOTAL: $ 12.250,50"]))
        let text = lines.joined(separator: "\n")
        #expect(text.contains("FACTURA B"))
        #expect(text.contains("30-71234567-1"))
        #expect(text.contains("12.250,50"))
    }

    @Test(arguments: zip(
        ["TOTAL: $ 12.250, 50", "CUIT 30 - 71234567 - 1", "Qty 2 x 3"],
        ["TOTAL: $ 12.250,50", "CUIT 30-71234567-1", "Qty 2 x 3"]
    ))
    func normalizesOCRArtifacts(raw: String, expected: String) {
        #expect(TextRecognizer.normalized(raw) == expected)
    }
}
