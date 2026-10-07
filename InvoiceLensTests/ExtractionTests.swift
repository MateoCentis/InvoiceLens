import Foundation
import Testing
@testable import InvoiceLens

/// OCR output of a typical Argentine "Factura B".
let sampleInvoiceLines = [
    "ORIGINAL",
    "B",
    "FARMACIA DEL CENTRO S.R.L.",
    "Razón Social: Farmacia del Centro S.R.L.",
    "Domicilio: San Martín 1234 - Santa Fe",
    "CUIT: 30-71234567-1",
    "FACTURA B COD. 06",
    "Punto de Venta: 0003 Comp. Nro: 00012345",
    "Fecha de Emisión: 03/10/2026",
    "Condición frente al IVA: Consumidor Final",
    "Ibuprofeno 400 mg x 20   2   $ 4.500,00   $ 9.000,00",
    "Alcohol en gel 250 ml   1   $ 3.250,50   $ 3.250,50",
    "Subtotal: $ 12.250,50",
    "IVA 21% (incluido): $ 2.126,12",
    "TOTAL: $ 12.250,50",
    "CAE N°: 74123456789012 Vto. CAE: 13/10/2026",
]

struct CUITTests {
    @Test(arguments: ["30-71234567-1", "30712345671", "20-12345678-6"])
    func validCUITs(_ value: String) {
        #expect(CUIT.isValid(value))
    }

    @Test(arguments: ["30-71234567-2", "123", "", "30-7123456-1"])
    func invalidCUITs(_ value: String) {
        #expect(!CUIT.isValid(value))
    }

    @Test func formatsElevenDigits() {
        #expect(CUIT.formatted("30712345671") == "30-71234567-1")
    }
}

struct AmountParserTests {
    @Test(arguments: zip(
        ["12.250,50", "12,250.50", "$ 1.234", "4500,5", "0,99", "1.234.567,89", "abc"],
        [Decimal(string: "12250.50"), Decimal(string: "12250.50"), 1234, Decimal(string: "4500.5"),
         Decimal(string: "0.99"), Decimal(string: "1234567.89"), nil]
    ))
    func parsesAmounts(raw: String, expected: Decimal?) {
        #expect(AmountParser.parse(raw) == expected)
    }
}

struct RuleBasedInvoiceExtractorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires")!
        return calendar
    }()

    @Test func extractsTypicalFacturaB() throws {
        let draft = RuleBasedInvoiceExtractor.extract(from: sampleInvoiceLines, calendar: calendar)

        #expect(draft.supplierName == "Farmacia del Centro S.R.L.")
        #expect(draft.supplierTaxID == "30-71234567-1")
        #expect(draft.invoiceType == .b)
        #expect(draft.invoiceNumber == "0003-00012345")
        #expect(draft.total == Decimal(string: "12250.50"))
        #expect(draft.taxAmount == Decimal(string: "2126.12"))

        let date = try #require(draft.issueDate)
        #expect(calendar.dateComponents([.year, .month, .day], from: date) == DateComponents(year: 2026, month: 10, day: 3))
    }

    @Test func ignoresCUITWithWrongCheckDigit() {
        #expect(RuleBasedInvoiceExtractor.firstValidCUIT(in: "CUIT 30-71234567-2 / 20-12345678-6") == "20-12345678-6")
    }

    @Test func readsDashedInvoiceNumber() {
        #expect(RuleBasedInvoiceExtractor.invoiceNumber(in: "Nº 0001-00004567") == "0001-00004567")
    }

    @Test func totalCanBeOnTheNextLine() {
        let lines = ["IMPORTE TOTAL", "$ 8.900,00"]
        #expect(RuleBasedInvoiceExtractor.total(in: lines) == 8_900)
    }

    @Test func percentagesAreNotAmounts() {
        #expect(RuleBasedInvoiceExtractor.amounts(in: "IVA 21% 2.100,00") == [2_100])
    }

    @Test func modelDraftGapsAreFilledByRules() {
        var model = InvoiceDraft()
        model.supplierName = "Farmacia del Centro"
        model.supplierTaxID = "30-00000000-0" // hallucinated, invalid
        let rules = RuleBasedInvoiceExtractor.extract(from: sampleInvoiceLines, calendar: calendar)

        let merged = model.fillingGaps(from: rules)
        #expect(merged.supplierName == "Farmacia del Centro")
        #expect(merged.supplierTaxID == "30-71234567-1")
        #expect(merged.total == Decimal(string: "12250.50"))
    }
}
