//
//  CumulativeBalanceChart.swift
//  ExpenseTracker
//
//  Running projected balance over the forecast period, drawn as a line with a marker
//  per month.
//

import SwiftUI

struct CumulativeBalanceChart: View {
    let points: [CumulativeBalancePoint]
    let isDarkTheme: Bool

    private let chartHeight: CGFloat = 140
    private let markerRadius: CGFloat = 3.5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if points.count < 2 {
                emptyState
            } else {
                HStack(alignment: .top, spacing: 8) {
                    yAxisLabels
                    plot
                }
                .frame(height: chartHeight)
            }
        }
    }
}

// MARK: - Scale

private extension CumulativeBalanceChart {

    var minBalance: Double { points.map(\.balance).min() ?? 0 }
    var maxBalance: Double { points.map(\.balance).max() ?? 0 }

    /// The line is a cumulative total, so it barely varies as a fraction of its own
    /// magnitude. Scaling from zero would flatten it into a straight line near the
    /// top of the chart, so the axis spans the actual range instead.
    ///
    /// Guarded against a zero span, which happens when income exactly covers the
    /// forecast every month.
    var span: Double {
        let range = maxBalance - minBalance
        return range > 0 ? range : 1
    }

    func normalized(_ balance: Double) -> Double {
        return (balance - minBalance) / span
    }

    var yAxisLabels: some View {
        VStack(alignment: .trailing) {
            Text(CurrencyInputFormatter.format(maxBalance))
            Spacer()
            Text(CurrencyInputFormatter.format(minBalance))
        }
        .font(.system(size: 9))
        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        .frame(width: 56)
    }
}

// MARK: - Plot

private extension CumulativeBalanceChart {

    var plot: some View {
        GeometryReader { geometry in
            let positions = pointPositions(in: geometry.size)

            ZStack {
                line(through: positions)
                markers(at: positions)
            }
        }
    }

    /// Inset vertically by the marker radius so the first and last markers are not
    /// clipped by the plot bounds.
    func pointPositions(in size: CGSize) -> [CGPoint] {
        guard points.count > 1 else { return [] }

        let usableHeight = size.height - markerRadius * 2
        let stepX = size.width / CGFloat(points.count - 1)

        return points.enumerated().map { index, point in
            CGPoint(
                x: CGFloat(index) * stepX,
                y: markerRadius + usableHeight * (1 - CGFloat(normalized(point.balance)))
            )
        }
    }

    func line(through positions: [CGPoint]) -> some View {
        Path { path in
            guard let first = positions.first else { return }
            path.move(to: first)
            positions.dropFirst().forEach { path.addLine(to: $0) }
        }
        .stroke(
            ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }

    func markers(at positions: [CGPoint]) -> some View {
        ForEach(Array(positions.enumerated()), id: \.offset) { _, position in
            Circle()
                .fill(ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme))
                .frame(width: markerRadius * 2, height: markerRadius * 2)
                .position(position)
        }
    }
}

// MARK: - Empty State

private extension CumulativeBalanceChart {

    var emptyState: some View {
        Text("no_data_yet".localized)
            .font(.system(size: 14))
            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            .frame(maxWidth: .infinity, minHeight: chartHeight)
    }
}
