//
//  OverviewBarChart.swift
//  ExpenseTracker
//
//  Monthly bar chart used by both the spending trend and the forecast. They differ
//  only in colour and data, so they share this.
//

import SwiftUI

struct OverviewBarChart: View {
    let points: [MonthlyAmountPoint]
    let barColor: Color
    let isDarkTheme: Bool

    private let chartHeight: CGFloat = 200
    private let gridLineCount = 4

    /// Axis top. Falls back to 1 on an empty or all-zero set so the bar height
    /// division below never hits zero.
    private var maxAmount: Double {
        max(points.map(\.amount).max() ?? 0, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if points.isEmpty {
                emptyState
            } else {
                chart
                monthLabels
            }
        }
    }
}

// MARK: - Chart

private extension OverviewBarChart {

    var chart: some View {
        HStack(alignment: .top, spacing: 8) {
            yAxisLabels
            plotArea
        }
        .frame(height: chartHeight)
    }

    /// Descending so the largest value sits at the top, matching the plot area.
    var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(0...gridLineCount, id: \.self) { step in
                let value = maxAmount * Double(gridLineCount - step) / Double(gridLineCount)

                Text(CurrencyInputFormatter.format(value))
                    .font(.system(size: 9))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .frame(maxHeight: .infinity, alignment: step == gridLineCount ? .bottom : .top)
            }
        }
        .frame(width: 56)
    }

    var plotArea: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                gridLines
                bars(availableHeight: geometry.size.height)
            }
        }
    }

    var gridLines: some View {
        VStack(spacing: 0) {
            ForEach(0...gridLineCount, id: \.self) { step in
                Rectangle()
                    .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.15))
                    .frame(height: 0.5)

                if step < gridLineCount {
                    Spacer(minLength: 0)
                }
            }
        }
    }

    func bars(availableHeight: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(points) { point in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(height: barHeight(for: point.amount, in: availableHeight))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// A month with no spending still gets a hairline, so the gap between "nothing
    /// recorded" and "no bar drawn" stays visible.
    func barHeight(for amount: Double, in availableHeight: CGFloat) -> CGFloat {
        guard amount > 0 else { return 1 }
        return max(CGFloat(amount / maxAmount) * availableHeight, 2)
    }
}

// MARK: - Month Labels

private extension OverviewBarChart {

    /// Twelve labels will not fit on a phone, so only every other month is named.
    /// The last month is always named — it is the one the reader looks for.
    var monthLabels: some View {
        HStack(spacing: 3) {
            ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                Group {
                    if shouldLabel(index: index) {
                        Text(Self.monthFormatter.string(from: point.month))
                            .font(.system(size: 9))
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.leading, 64)
    }

    func shouldLabel(index: Int) -> Bool {
        guard points.count > 6 else { return true }
        return index == points.count - 1 || (points.count - 1 - index) % 2 == 0
    }

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM")
        return formatter
    }()
}

// MARK: - Empty State

private extension OverviewBarChart {

    var emptyState: some View {
        Text("no_data_yet".localized)
            .font(.system(size: 14))
            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity, minHeight: chartHeight)
    }
}
