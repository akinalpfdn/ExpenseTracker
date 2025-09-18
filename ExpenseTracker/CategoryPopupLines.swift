//
//  CategoryPopupLines.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct CategoryPopupLines: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var expenseViewModel: ExpenseViewModel

    let categories: [String]
    let timeRange: ComparisonTimeRange
    let comparisonType: ComparisonType

    @State private var selectedCategory: String? = nil
    @State private var showingCategoryDetail = false
    @State private var animateChart = false

    private var chartData: [CategoryComparisonData] {
        generateChartData()
    }

    private var maxAmount: Double {
        chartData.flatMap { $0.dataPoints }.map { $0.amount }.max() ?? 0
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView

                if chartData.isEmpty {
                    emptyStateView
                } else {
                    chartContentView
                }
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCategoryDetail) {
                if let selectedCategory = selectedCategory {
                    CategoryDetailBottomSheet(
                        categoryId: selectedCategory,
                        expenses: expenseViewModel.expenses,
                        month: Date()
                    )
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animateChart = true
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                Text(L("category_comparison"))
                    .font(AppTypography.navigationTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
            .padding()

            // Time range and comparison type indicators
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.primaryOrange)

                    Text(timeRange.displayName)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: comparisonType.iconName)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(AppColors.primaryRed)

                    Text(comparisonType.displayName)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }
            }
            .padding(.horizontal)
            .padding(.bottom)

            Divider()
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme).opacity(0.3))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(L("no_data_to_compare"))
                .font(AppTypography.titleSmall)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Text(L("select_categories_to_compare"))
                .font(AppTypography.bodyMedium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var chartContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                chartView
                legendView
                summaryStatsView
            }
            .padding()
        }
    }

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("spending_trends"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            Chart {
                ForEach(chartData, id: \.categoryId) { categoryData in
                    ForEach(categoryData.dataPoints, id: \.id) { dataPoint in
                        LineMark(
                            x: .value(L("date"), dataPoint.date),
                            y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                        )
                        .foregroundStyle(categoryData.color)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .opacity(selectedCategory == nil || selectedCategory == categoryData.categoryId ? 1.0 : 0.3)

                        PointMark(
                            x: .value(L("date"), dataPoint.date),
                            y: .value(L("amount"), animateChart ? dataPoint.amount : 0)
                        )
                        .foregroundStyle(categoryData.color)
                        .symbolSize(selectedCategory == categoryData.categoryId ? 60 : 30)
                        .opacity(selectedCategory == nil || selectedCategory == categoryData.categoryId ? 1.0 : 0.3)
                    }
                }
            }
            .frame(height: 250)
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
                    .background(ThemeColors.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(8)
            }
            .animation(.easeInOut(duration: 0.8), value: animateChart)
            .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("categories"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(chartData, id: \.categoryId) { categoryData in
                    legendItem(for: categoryData)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private func legendItem(for categoryData: CategoryComparisonData) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(categoryData.color)
                .frame(width: 4, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryData.categoryName)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)

                HStack {
                    Text(formatCurrency(categoryData.totalAmount))
                        .font(AppTypography.labelSmall)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Spacer()

                    if let trend = categoryData.trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend.iconName)
                                .font(AppTypography.labelSmall)
                                .foregroundColor(trend.color)

                            Text(trend.displayText)
                                .font(AppTypography.labelSmall)
                                .foregroundColor(trend.color)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedCategory == categoryData.categoryId ?
                      categoryData.color.opacity(0.1) :
                      Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    selectedCategory == categoryData.categoryId ?
                    categoryData.color.opacity(0.5) :
                    Color.clear,
                    lineWidth: 1
                )
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedCategory == categoryData.categoryId {
                    selectedCategory = nil
                } else {
                    selectedCategory = categoryData.categoryId
                }
            }
        }
        .onLongPressGesture {
            selectedCategory = categoryData.categoryId
            showingCategoryDetail = true
        }
    }

    private var summaryStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("comparison_summary"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                summaryStatItem(
                    title: L("highest_spending"),
                    value: highestSpendingCategory,
                    icon: "arrow.up.circle.fill",
                    color: AppColors.primaryRed
                )

                summaryStatItem(
                    title: L("most_consistent"),
                    value: mostConsistentCategory,
                    icon: "chart.line.flattrend.xyaxis",
                    color: AppColors.successGreen
                )

                summaryStatItem(
                    title: L("biggest_increase"),
                    value: biggestIncreaseCategory,
                    icon: "trending.up",
                    color: AppColors.primaryOrange
                )

                summaryStatItem(
                    title: L("biggest_decrease"),
                    value: biggestDecreaseCategory,
                    icon: "trending.down",
                    color: .blue
                )
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private func summaryStatItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(color)

                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    .lineLimit(1)
            }

            Text(value)
                .font(AppTypography.bodyMedium)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    private var highestSpendingCategory: String {
        chartData.max(by: { $0.totalAmount < $1.totalAmount })?.categoryName ?? L("none")
    }

    private var mostConsistentCategory: String {
        chartData.min(by: { $0.variance < $1.variance })?.categoryName ?? L("none")
    }

    private var biggestIncreaseCategory: String {
        chartData.filter { ($0.trend?.direction ?? .neutral) == .up }
            .max(by: { ($0.trend?.percentage ?? 0) < ($1.trend?.percentage ?? 0) })?
            .categoryName ?? L("none")
    }

    private var biggestDecreaseCategory: String {
        chartData.filter { ($0.trend?.direction ?? .neutral) == .down }
            .max(by: { ($0.trend?.percentage ?? 0) < ($1.trend?.percentage ?? 0) })?
            .categoryName ?? L("none")
    }

    // MARK: - Helper Functions

    private func generateChartData() -> [CategoryComparisonData] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: timeRange.dateComponent, value: -timeRange.value, to: endDate) ?? endDate

        let filteredExpenses = expenseViewModel.expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate && categories.contains(expense.categoryId)
        }

        return categories.enumerated().compactMap { index, categoryId in
            let categoryExpenses = filteredExpenses.filter { $0.categoryId == categoryId }
            guard !categoryExpenses.isEmpty else { return nil }

            let dataPoints = generateDataPoints(for: categoryExpenses, in: startDate...endDate)
            let totalAmount = categoryExpenses.reduce(0) { $0 + $1.amount }
            let trend = calculateTrend(for: dataPoints)
            let variance = calculateVariance(for: dataPoints)

            return CategoryComparisonData(
                categoryId: categoryId,
                categoryName: getCategoryName(categoryId),
                color: getCategoryColor(index),
                dataPoints: dataPoints,
                totalAmount: totalAmount,
                trend: trend,
                variance: variance
            )
        }
    }

    private func generateDataPoints(for expenses: [Expense], in range: ClosedRange<Date>) -> [ComparisonDataPoint] {
        let calendar = Calendar.current
        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            timeRange.groupingKey(for: expense.date, calendar: calendar)
        }

        var dataPoints: [ComparisonDataPoint] = []
        var currentDate = range.lowerBound

        while currentDate <= range.upperBound {
            let key = timeRange.groupingKey(for: currentDate, calendar: calendar)
            let amount = groupedExpenses[key]?.reduce(0) { $0 + $1.amount } ?? 0

            dataPoints.append(ComparisonDataPoint(
                id: UUID(),
                date: currentDate,
                amount: amount
            ))

            currentDate = calendar.date(byAdding: timeRange.incrementComponent, value: 1, to: currentDate) ?? currentDate
        }

        return dataPoints
    }

    private func calculateTrend(for dataPoints: [ComparisonDataPoint]) -> TrendData? {
        guard dataPoints.count >= 2 else { return nil }

        let firstHalf = dataPoints.prefix(dataPoints.count / 2)
        let secondHalf = dataPoints.suffix(dataPoints.count / 2)

        let firstAverage = firstHalf.map { $0.amount }.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.map { $0.amount }.reduce(0, +) / Double(secondHalf.count)

        guard firstAverage > 0 else { return nil }

        let percentageChange = ((secondAverage - firstAverage) / firstAverage) * 100

        let direction: TrendDirection
        if abs(percentageChange) < 5 {
            direction = .neutral
        } else if percentageChange > 0 {
            direction = .up
        } else {
            direction = .down
        }

        return TrendData(
            direction: direction,
            percentage: abs(percentageChange)
        )
    }

    private func calculateVariance(for dataPoints: [ComparisonDataPoint]) -> Double {
        let amounts = dataPoints.map { $0.amount }
        let average = amounts.reduce(0, +) / Double(amounts.count)
        let variance = amounts.map { pow($0 - average, 2) }.reduce(0, +) / Double(amounts.count)
        return sqrt(variance) // Standard deviation
    }

    private func getCategoryName(_ categoryId: String) -> String {
        return expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private func getCategoryColor(_ index: Int) -> Color {
        let colors: [Color] = [
            AppColors.primaryOrange,
            AppColors.primaryRed,
            AppColors.successGreen,
            .blue,
            .purple,
            .pink,
            .yellow,
            .cyan,
            .indigo,
            .mint
        ]
        return colors[index % colors.count]
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = expenseViewModel.settingsManager?.currency ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

// MARK: - Supporting Types

struct CategoryComparisonData {
    let categoryId: String
    let categoryName: String
    let color: Color
    let dataPoints: [ComparisonDataPoint]
    let totalAmount: Double
    let trend: TrendData?
    let variance: Double
}

struct ComparisonDataPoint {
    let id: UUID
    let date: Date
    let amount: Double
}

struct TrendData {
    let direction: TrendDirection
    let percentage: Double

    var color: Color {
        switch direction {
        case .up:
            return AppColors.primaryRed
        case .down:
            return AppColors.successGreen
        case .neutral:
            return Color.gray
        }
    }

    var iconName: String {
        switch direction {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .neutral:
            return "minus"
        }
    }

    var displayText: String {
        switch direction {
        case .up, .down:
            return String(format: "%.1f%%", percentage)
        case .neutral:
            return L("stable")
        }
    }
}

enum TrendDirection {
    case up, down, neutral
}

enum ComparisonTimeRange: String, CaseIterable {
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

enum ComparisonType: String, CaseIterable {
    case amount = "amount"
    case frequency = "frequency"
    case average = "average"

    var displayName: String {
        switch self {
        case .amount:
            return L("total_amount")
        case .frequency:
            return L("frequency")
        case .average:
            return L("average_amount")
        }
    }

    var iconName: String {
        switch self {
        case .amount:
            return "dollarsign.circle"
        case .frequency:
            return "number.circle"
        case .average:
            return "chart.bar"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CategoryPopupLines_Previews: PreviewProvider {
    static var previews: some View {
        CategoryPopupLines(
            expenseViewModel: ExpenseViewModel.preview,
            categories: ["food", "transport", "shopping"],
            timeRange: .last3Months,
            comparisonType: .amount
        )
    }
}
#endif