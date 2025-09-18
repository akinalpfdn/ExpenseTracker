//
//  MonthlyLineChart.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct MonthlyLineChart: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let expenses: [Expense]
    let timeRange: ChartTimeRange
    let showComparison: Bool

    @State private var selectedDataPoint: ChartDataPoint? = nil
    @State private var showingDetails = false
    @State private var animateChart = false

    private var chartData: [ChartDataPoint] {
        generateChartData()
    }

    private var comparisonData: [ChartDataPoint] {
        guard showComparison else { return [] }
        return generateComparisonData()
    }

    private var maxAmount: Double {
        let currentMax = chartData.map { $0.amount }.max() ?? 0
        let comparisonMax = comparisonData.map { $0.amount }.max() ?? 0
        return max(currentMax, comparisonMax)
    }

    private var averageAmount: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.amount }.reduce(0, +) / Double(chartData.count)
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView

            if chartData.isEmpty {
                emptyStateView
            } else {
                chartView
                statisticsView
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingDetails) {
            if let selectedDataPoint = selectedDataPoint {
                dataPointDetailsView(for: selectedDataPoint)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animateChart = true
            }
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(AppTypography.bodyLarge)
                .foregroundColor(AppColors.primaryOrange)

            Text(L("spending_trends"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Spacer()

            Menu {
                Button(L("last_30_days")) {
                    // Handle time range change
                }
                Button(L("last_3_months")) {
                    // Handle time range change
                }
                Button(L("last_6_months")) {
                    // Handle time range change
                }
                Button(L("last_year")) {
                    // Handle time range change
                }
            } label: {
                HStack(spacing: 4) {
                    Text(timeRange.displayName)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.primaryOrange)

                    Image(systemName: "chevron.down")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.flattrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(L("no_data_available"))
                .font(AppTypography.bodyLarge)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
        }
        .frame(height: 200)
    }

    private var chartView: some View {
        Chart {
            // Main trend line
            ForEach(chartData, id: \.id) { dataPoint in
                LineMark(
                    x: .value(L("date"), dataPoint.date),
                    y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                )
                .foregroundStyle(AppColors.primaryGradient)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                AreaMark(
                    x: .value(L("date"), dataPoint.date),
                    y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppColors.primaryOrange.opacity(0.3),
                            AppColors.primaryOrange.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Data points
                PointMark(
                    x: .value(L("date"), dataPoint.date),
                    y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                )
                .foregroundStyle(AppColors.primaryOrange)
                .symbolSize(selectedDataPoint?.id == dataPoint.id ? 80 : 40)
            }

            // Comparison line (if enabled)
            if showComparison {
                ForEach(comparisonData, id: \.id) { dataPoint in
                    LineMark(
                        x: .value(L("date"), dataPoint.date),
                        y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                    )
                    .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5]))
                }
            }

            // Average line
            RuleMark(y: .value(L("average"), averageAmount))
                .foregroundStyle(AppColors.successGreen)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .annotation(position: .topTrailing) {
                    Text(L("average"))
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.successGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.successGreen.opacity(0.1))
                        )
                }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: timeRange.axisStride)) { _ in
                AxisValueLabel()
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme))
                AxisGridLine()
                    .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme).opacity(0.2))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(AppTypography.labelSmall)
                    .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme))
                AxisGridLine()
                    .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme).opacity(0.2))
            }
        }
        .chartPlotStyle { plotArea in
            plotArea
                .background(ThemeColors.backgroundColor(for: colorScheme).opacity(0.5))
                .cornerRadius(8)
        }
        .chartSelection(value: .constant(selectedDataPoint?.date))
        .onTapGesture { location in
            // Handle chart tap for data point selection
        }
        .animation(.easeInOut(duration: 0.8), value: animateChart)
    }

    private var statisticsView: some View {
        HStack {
            statisticItem(
                title: L("total"),
                value: formatCurrency(chartData.map { $0.amount }.reduce(0, +)),
                icon: "sum",
                color: AppColors.primaryOrange
            )

            Divider()
                .frame(height: 40)

            statisticItem(
                title: L("average"),
                value: formatCurrency(averageAmount),
                icon: "chart.bar.fill",
                color: AppColors.successGreen
            )

            Divider()
                .frame(height: 40)

            statisticItem(
                title: L("highest"),
                value: formatCurrency(maxAmount),
                icon: "arrow.up.circle.fill",
                color: AppColors.primaryRed
            )
        }
    }

    private func statisticItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(AppTypography.bodyMedium)
                .foregroundColor(color)

            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(value)
                .font(AppTypography.labelMedium)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    private func dataPointDetailsView(for dataPoint: ChartDataPoint) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("date"))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                        Text(formatDate(dataPoint.date))
                            .font(AppTypography.bodyLarge)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(L("amount"))
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                        Text(formatCurrency(dataPoint.amount))
                            .font(AppTypography.expenseAmountLarge)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }

                // Additional details would go here
                Spacer()
            }
            .padding()
            .navigationTitle(L("details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        showingDetails = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func generateChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: timeRange.dateComponent, value: -timeRange.value, to: endDate) ?? endDate

        let groupedExpenses = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }) { expense in
            timeRange.groupingKey(for: expense.date, calendar: calendar)
        }

        var dataPoints: [ChartDataPoint] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let key = timeRange.groupingKey(for: currentDate, calendar: calendar)
            let amount = groupedExpenses[key]?.reduce(0) { $0 + $1.amount } ?? 0

            dataPoints.append(ChartDataPoint(
                id: UUID(),
                date: currentDate,
                amount: amount,
                label: timeRange.labelFormatter.string(from: currentDate)
            ))

            currentDate = calendar.date(byAdding: timeRange.incrementComponent, value: 1, to: currentDate) ?? currentDate
        }

        return dataPoints
    }

    private func generateComparisonData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: timeRange.dateComponent, value: -timeRange.value, to: Date()) ?? Date()
        let startDate = calendar.date(byAdding: timeRange.dateComponent, value: -timeRange.value, to: endDate) ?? endDate

        let groupedExpenses = Dictionary(grouping: expenses.filter { $0.date >= startDate && $0.date <= endDate }) { expense in
            timeRange.groupingKey(for: expense.date, calendar: calendar)
        }

        var dataPoints: [ChartDataPoint] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let key = timeRange.groupingKey(for: currentDate, calendar: calendar)
            let amount = groupedExpenses[key]?.reduce(0) { $0 + $1.amount } ?? 0

            // Adjust the date to align with current period
            let adjustedDate = calendar.date(byAdding: timeRange.dateComponent, value: timeRange.value, to: currentDate) ?? currentDate

            dataPoints.append(ChartDataPoint(
                id: UUID(),
                date: adjustedDate,
                amount: amount,
                label: timeRange.labelFormatter.string(from: adjustedDate)
            ))

            currentDate = calendar.date(byAdding: timeRange.incrementComponent, value: 1, to: currentDate) ?? currentDate
        }

        return dataPoints
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expenseViewModel.settingsManager?.currency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func formatDate(_ date: Date) -> String {
        timeRange.labelFormatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct ChartDataPoint {
    let id: UUID
    let date: Date
    let amount: Double
    let label: String
}

enum ChartTimeRange: String, CaseIterable {
    case last30Days = "last30Days"
    case last3Months = "last3Months"
    case last6Months = "last6Months"
    case lastYear = "lastYear"

    var displayName: String {
        switch self {
        case .last30Days:
            return L("last_30_days")
        case .last3Months:
            return L("last_3_months")
        case .last6Months:
            return L("last_6_months")
        case .lastYear:
            return L("last_year")
        }
    }

    var dateComponent: Calendar.Component {
        switch self {
        case .last30Days:
            return .day
        case .last3Months, .last6Months:
            return .month
        case .lastYear:
            return .year
        }
    }

    var incrementComponent: Calendar.Component {
        switch self {
        case .last30Days:
            return .day
        case .last3Months, .last6Months, .lastYear:
            return .month
        }
    }

    var value: Int {
        switch self {
        case .last30Days:
            return 30
        case .last3Months:
            return 3
        case .last6Months:
            return 6
        case .lastYear:
            return 1
        }
    }

    var axisStride: Calendar.Component {
        switch self {
        case .last30Days:
            return .weekOfYear
        case .last3Months, .last6Months:
            return .month
        case .lastYear:
            return .quarter
        }
    }

    var labelFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch self {
        case .last30Days:
            formatter.dateFormat = "M/d"
        case .last3Months, .last6Months:
            formatter.dateFormat = "MMM"
        case .lastYear:
            formatter.dateFormat = "MMM yyyy"
        }

        return formatter
    }

    func groupingKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch self {
        case .last30Days:
            formatter.dateFormat = "yyyy-MM-dd"
        case .last3Months, .last6Months, .lastYear:
            formatter.dateFormat = "yyyy-MM"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct MonthlyLineChart_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = (0..<30).map { days in
            Expense(
                amount: Double.random(in: 50...500),
                categoryId: "food",
                subCategoryId: "restaurants",
                description: "Test expense",
                date: Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            )
        }

        MonthlyLineChart(
            expenseViewModel: ExpenseViewModel.preview,
            expenses: mockExpenses,
            timeRange: .last30Days,
            showComparison: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif