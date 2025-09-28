//
//  MonthlyLineChart.swift
//  ExpenseTracker
//
//  Created by migration from Android MonthlyLineChart.kt
//

import SwiftUI

struct ChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let day: Int
    let amount: Double
}

enum ExpenseFilterType: String, CaseIterable {
    case all = "ALL"
    case recurring = "RECURRING"
    case oneTime = "ONE_TIME"

    var displayName: String {
        switch self {
        case .all:
            return "all".localized
        case .recurring:
            return "recurring_label".localized
        case .oneTime:
            return "one_time_expense".localized
        }
    }
}

struct MonthlyLineChart: View {
    let data: [ChartDataPoint]
    let currency: String
    let isDarkTheme: Bool

    @State private var isCollapsed = false

    private var maxAmount: Double {
        data.map(\.amount).max() ?? 0.0
    }

    private var avgAmount: Double {
        data.isEmpty ? 0.0 : data.map(\.amount).reduce(0, +) / Double(data.count)
    }

    init(
        data: [ChartDataPoint],
        currency: String = "₺",
        isDarkTheme: Bool = true
    ) {
        self.data = data
        self.currency = currency
        self.isDarkTheme = isDarkTheme
    }

    var body: some View {
        VStack(spacing: 0) {
            chartCard
        }
    }
}

// MARK: - Chart Card
extension MonthlyLineChart {
    private var chartCard: some View {
        VStack(spacing: 16) {
            headerRow

            if !isCollapsed {
                chartContent
            }
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }

    private var headerRow: some View {
        HStack {
            Text("period_expense_trend".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Button(action: toggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .font(.system(size: 16))
            }
        }
        .onTapGesture {
            toggleCollapse()
        }
    }

    private var chartContent: some View {
        VStack(spacing: 8) {
            if data.isEmpty {
                emptyStateView
            } else {
                lineChartView
                legendView
            }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Text("no_data_found".localized)
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
        .frame(height: 250)
    }

    private var lineChartView: some View {
        LineChartCanvas(
            data: data,
            maxAmount: maxAmount,
            isDarkTheme: isDarkTheme
        )
        .frame(height: 250)
    }

    private var legendView: some View {
        HStack {
            Text("highest".localized + ": \(currency) \(NumberFormatter.formatAmount(maxAmount))")
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Spacer()

            Text("average".localized + ": \(currency) \(NumberFormatter.formatAmount(avgAmount))")
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }
}

// MARK: - Helper Methods
extension MonthlyLineChart {
    private func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCollapsed.toggle()
        }
    }
}

struct LineChartCanvas: View {
    let data: [ChartDataPoint]
    let maxAmount: Double
    let isDarkTheme: Bool

    private let padding: CGFloat = 25

    var body: some View {
        Canvas { context, size in
            drawLineChart(context: context, size: size)
        }
    }
}

// MARK: - Canvas Drawing
extension LineChartCanvas {
    private func drawLineChart(context: GraphicsContext, size: CGSize) {
        let chartWidth = size.width - padding * 2
        let chartHeight = size.height - padding * 2

        drawGridAndLabels(context: context, size: size, chartWidth: chartWidth, chartHeight: chartHeight)

        guard !data.isEmpty && maxAmount > 0 else { return }

        let points = calculateDataPoints(chartWidth: chartWidth, chartHeight: chartHeight)

        drawGradientArea(context: context, points: points, size: size)
        drawLine(context: context, points: points)
        drawPoints(context: context, points: points)
    }

    private func drawGridAndLabels(context: GraphicsContext, size: CGSize, chartWidth: CGFloat, chartHeight: CGFloat) {
        let textColor: Color = isDarkTheme ? .white : .black
        let gridColor: Color = isDarkTheme ? Color.white.opacity(0.1) : Color.black.opacity(0.1)

        // Y-axis grid lines and labels
        for i in 0...4 {
            let y = padding + (chartHeight / 4) * CGFloat(i)
            let amount = maxAmount * Double(4 - i) / 4

            // Draw grid line (skip first line)
            if i > 0 {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: padding, y: y))
                        path.addLine(to: CGPoint(x: size.width - padding, y: y))
                    },
                    with: .color(gridColor),
                    lineWidth: 1
                )
            }

            // Draw Y-axis label
            let labelText = NumberFormatter.formatAmount(amount)
            context.draw(
                Text(labelText)
                    .font(.system(size: 10))
                    .foregroundColor(textColor),
                at: CGPoint(x: padding - 5, y: y),
                anchor: .trailing
            )
        }

        // X-axis labels
        let xAxisStep = max(1, data.count / 10)
        for i in stride(from: 0, to: data.count, by: xAxisStep) {
            let x = padding + (chartWidth / max(1, CGFloat(data.count - 1))) * CGFloat(i)
            let day = data[i].day

            context.draw(
                Text("\(day)")
                    .font(.system(size: 10))
                    .foregroundColor(textColor),
                at: CGPoint(x: x, y: size.height - padding + 15),
                anchor: .center
            )
        }
    }

    private func calculateDataPoints(chartWidth: CGFloat, chartHeight: CGFloat) -> [CGPoint] {
        return data.enumerated().map { index, point in
            let x = padding + (chartWidth / max(1, CGFloat(data.count - 1))) * CGFloat(index)
            let y = padding + chartHeight - CGFloat(point.amount / maxAmount) * chartHeight
            return CGPoint(x: x, y: y)
        }
    }

    private func drawGradientArea(context: GraphicsContext, points: [CGPoint], size: CGSize) {
        guard let firstPoint = points.first, let lastPoint = points.last else { return }

        var gradientPath = Path()
        gradientPath.move(to: firstPoint)

        for point in points.dropFirst() {
            gradientPath.addLine(to: point)
        }

        gradientPath.addLine(to: CGPoint(x: lastPoint.x, y: size.height - padding))
        gradientPath.addLine(to: CGPoint(x: firstPoint.x, y: size.height - padding))
        gradientPath.closeSubpath()

        context.fill(gradientPath, with: .color(AppColors.primaryOrange.opacity(0.1)))
    }

    private func drawLine(context: GraphicsContext, points: [CGPoint]) {
        guard let firstPoint = points.first else { return }

        var linePath = Path()
        linePath.move(to: firstPoint)

        for point in points.dropFirst() {
            linePath.addLine(to: point)
        }

        context.stroke(linePath, with: .color(AppColors.primaryOrange), lineWidth: 3)
    }

    private func drawPoints(context: GraphicsContext, points: [CGPoint]) {
        for point in points {
            // Outer circle
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)),
                with: .color(AppColors.primaryOrange)
            )

            // Inner circle
            let innerColor: Color = isDarkTheme ? .black : .white
            context.fill(
                Path(ellipseIn: CGRect(x: point.x - 1, y: point.y - 1, width: 2, height: 2)),
                with: .color(innerColor)
            )
        }
    }
}

// MARK: - Preview
struct MonthlyLineChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = [
            ChartDataPoint(day: 1, amount: 100.0),
            ChartDataPoint(day: 5, amount: 250.0),
            ChartDataPoint(day: 10, amount: 180.0),
            ChartDataPoint(day: 15, amount: 320.0),
            ChartDataPoint(day: 20, amount: 200.0),
            ChartDataPoint(day: 25, amount: 400.0),
            ChartDataPoint(day: 30, amount: 150.0)
        ]

        VStack(spacing: 20) {
            MonthlyLineChart(
                data: sampleData,
                currency: "₺",
                isDarkTheme: true
            )

            MonthlyLineChart(
                data: [],
                currency: "₺",
                isDarkTheme: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}