import Charts
import SwiftUI

/// Monthly spending over the last six months, with Swift Charts.
struct SpendingChart: View {
    let invoices: [Invoice]

    private struct MonthTotal: Identifiable {
        let month: Date
        let total: Double
        var id: Date { month }
    }

    private var monthTotals: [MonthTotal] {
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        let months = (0..<6).reversed().compactMap { calendar.date(byAdding: .month, value: -$0, to: thisMonth) }
        let totals = Dictionary(grouping: invoices) {
            calendar.dateInterval(of: .month, for: $0.issueDate)?.start ?? $0.issueDate
        }.mapValues { $0.map(\.total).reduce(0, +) }
        return months.map { MonthTotal(month: $0, total: NSDecimalNumber(decimal: totals[$0] ?? 0).doubleValue) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 6 months")
                .font(.headline)
            Chart(monthTotals) { item in
                BarMark(
                    x: .value("Month", item.month, unit: .month),
                    y: .value("Total", item.total)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount, format: .number.notation(.compactName))
                        }
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly spending chart for the last six months")
    }
}
