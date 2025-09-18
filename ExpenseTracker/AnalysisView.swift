//
//  AnalysisView.swift
//  ExpenseTracker
//
//  Comprehensive expense analysis and charts screen with multiple visualization types
//

import SwiftUI
import Charts

struct AnalysisView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - State

    @State private var selectedTimeframe: AnalysisTimeframe = .thisMonth
    @State private var selectedChartType: ChartType = .pieChart
    @State private var showingFilters = false
    @State private var showingExportOptions = false
    @State private var selectedMetrics: Set<AnalysisMetric> = [.totalSpending, .categoryBreakdown]

    // Animation state
    @State private var isLoaded = false
    @State private var animateCharts = false

    // Chart data
    @State private var chartData: [ChartDataPoint] = []
    @State private var trendData: [TrendDataPoint] = []

    // Scroll position for analytics cards
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 20) {
                        // MARK: - Header Section
                        headerSection

                        // MARK: - Quick Stats Cards
                        quickStatsSection

                        // MARK: - Chart Selection
                        chartSelectionSection

                        // MARK: - Main Chart
                        mainChartSection

                        // MARK: - Trend Analysis
                        trendAnalysisSection

                        // MARK: - Category Summary
                        categorySummarySection

                        // MARK: - Insights Section
                        insightsSection

                        // MARK: - Detailed Metrics
                        detailedMetricsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshAnalytics()
                }
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                loadInitialData()
            }
            .sheet(isPresented: $showingFilters) {
                AnalysisFiltersView(
                    selectedTimeframe: $selectedTimeframe,
                    selectedMetrics: $selectedMetrics
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("expense_analysis"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .themedTextColor()

                    Text(selectedTimeframe.displayName)
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                HStack(spacing: 12) {
                    // Filters button
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .themedTextColor()
                            .frame(width: 44, height: 44)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }

                    // Export button
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .themedTextColor()
                            .frame(width: 44, height: 44)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }
                }
            }

            // Timeframe selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnalysisTimeframe.allCases, id: \.rawValue) { timeframe in
                        TimeframeChip(
                            timeframe: timeframe,
                            isSelected: selectedTimeframe == timeframe
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeframe = timeframe
                            }
                            loadAnalyticsData()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("quick_overview"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()
            }

            HStack(spacing: 12) {
                // Total spending
                AnalyticsStatCard(
                    title: L("total_spending"),
                    value: expenseViewModel.formattedTotalAmount,
                    subtitle: L("expenses_count", expenseViewModel.filteredExpenseCount),
                    icon: "creditcard.fill",
                    color: .orange,
                    trend: calculateSpendingTrend()
                )

                // Average per day
                AnalyticsStatCard(
                    title: L("avg_per_day"),
                    value: formatCurrency(calculateAveragePerDay()),
                    subtitle: L("current_period"),
                    icon: "calendar",
                    color: .blue,
                    trend: calculateDailyAverageTrend()
                )
            }

            HStack(spacing: 12) {
                // Most expensive category
                AnalyticsStatCard(
                    title: L("top_category"),
                    value: topCategoryName,
                    subtitle: formatCurrency(topCategoryAmount),
                    icon: "chart.pie.fill",
                    color: .green,
                    trend: .neutral
                )

                // Budget efficiency
                AnalyticsStatCard(
                    title: L("budget_efficiency"),
                    value: "\(Int(budgetEfficiency))%",
                    subtitle: budgetEfficiencyLabel,
                    icon: "target",
                    color: budgetEfficiencyColor,
                    trend: budgetEfficiencyTrend
                )
            }
        }
    }

    // MARK: - Chart Selection Section

    private var chartSelectionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L("visualization"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChartType.allCases, id: \.rawValue) { chartType in
                        ChartTypeButton(
                            chartType: chartType,
                            isSelected: selectedChartType == chartType
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedChartType = chartType
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Main Chart Section

    private var mainChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(selectedChartType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                if expenseViewModel.isLoadingAnalytics {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(0.8)
                }
            }

            // Chart container
            Group {
                switch selectedChartType {
                case .pieChart:
                    CategoryDistributionChart(
                        data: expenseViewModel.categoryBreakdown,
                        showLegend: true
                    )
                    .frame(height: 300)

                case .barChart:
                    MonthlyLineChart(
                        data: expenseViewModel.monthlyTrend,
                        currency: settingsManager.currency
                    )
                    .frame(height: 250)

                case .lineChart:
                    TrendLineChart(
                        data: trendData,
                        timeframe: selectedTimeframe
                    )
                    .frame(height: 250)

                case .heatmap:
                    SpendingHeatmapChart(
                        data: generateHeatmapData(),
                        timeframe: selectedTimeframe
                    )
                    .frame(height: 200)
                }
            }
            .themedCardBackground()
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(animateCharts ? 1.0 : 0.95)
            .opacity(animateCharts ? 1.0 : 0.8)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateCharts)
        }
    }

    // MARK: - Trend Analysis Section

    private var trendAnalysisSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("spending_trends"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                Button(L("view_details")) {
                    // Navigate to detailed trend analysis
                }
                .font(.caption)
                .foregroundColor(.orange)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Weekly trend
                    TrendInsightCard(
                        title: L("weekly_trend"),
                        change: calculateWeeklyChange(),
                        description: L("vs_previous_week"),
                        icon: "calendar.badge.clock"
                    )

                    // Monthly trend
                    TrendInsightCard(
                        title: L("monthly_trend"),
                        change: calculateMonthlyChange(),
                        description: L("vs_previous_month"),
                        icon: "calendar"
                    )

                    // Category trend
                    TrendInsightCard(
                        title: L("category_shift"),
                        change: calculateCategoryShift(),
                        description: L("biggest_change"),
                        icon: "arrow.up.arrow.down"
                    )

                    // Forecast
                    TrendInsightCard(
                        title: L("forecast"),
                        change: calculateForecast(),
                        description: L("next_month_prediction"),
                        icon: "crystal.ball"
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Category Summary Section

    private var categorySummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("category_breakdown"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                Button(L("manage_categories")) {
                    // Navigate to category management
                }
                .font(.caption)
                .foregroundColor(.orange)
            }

            CategorySummarySection(
                categoryAnalytics: expenseViewModel.categoryAnalytics,
                totalAmount: expenseViewModel.totalFilteredAmount,
                onCategoryTap: { categoryId in
                    // Handle category tap
                }
            )
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("smart_insights"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .themedSecondaryTextColor()
            }

            LazyVStack(spacing: 12) {
                ForEach(generateInsights(), id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }

    // MARK: - Detailed Metrics Section

    private var detailedMetricsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("detailed_metrics"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: L("expense_frequency"),
                    value: "\(expenseViewModel.filteredExpenseCount)",
                    subtitle: L("total_transactions"),
                    icon: "number.circle"
                )

                MetricCard(
                    title: L("avg_transaction"),
                    value: formatCurrency(expenseViewModel.averageExpenseAmount),
                    subtitle: L("per_expense"),
                    icon: "chart.bar.doc.horizontal"
                )

                MetricCard(
                    title: L("spending_days"),
                    value: "\(calculateSpendingDays())",
                    subtitle: L("out_of_period"),
                    icon: "calendar.badge.plus"
                )

                MetricCard(
                    title: L("largest_expense"),
                    value: formatCurrency(findLargestExpense()),
                    subtitle: L("single_transaction"),
                    icon: "arrow.up.circle"
                )
            }
        }
    }

    // MARK: - Helper Methods

    private func loadInitialData() {
        guard !isLoaded else { return }

        Task {
            await refreshAnalytics()

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    isLoaded = true
                    animateCharts = true
                }
            }
        }
    }

    private func refreshAnalytics() async {
        await expenseViewModel.refreshAnalytics()
        loadAnalyticsData()
    }

    private func loadAnalyticsData() {
        // Generate chart data based on selected timeframe
        chartData = generateChartData()
        trendData = generateTrendData()
    }

    private func generateChartData() -> [ChartDataPoint] {
        // Convert expense data to chart data points
        let groupedExpenses = expenseViewModel.categoryBreakdown
        return groupedExpenses.map { (categoryId, amount) in
            ChartDataPoint(
                id: categoryId,
                label: getCategoryName(categoryId),
                value: amount,
                color: getCategoryColor(categoryId)
            )
        }
    }

    private func generateTrendData() -> [TrendDataPoint] {
        // Generate trend data based on timeframe
        let calendar = Calendar.current
        let now = Date()

        switch selectedTimeframe {
        case .lastWeek:
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let dayExpenses = getExpensesForDate(date)
                return TrendDataPoint(
                    date: date,
                    value: dayExpenses.reduce(0) { $0 + $1.amount }
                )
            }.reversed()

        case .thisMonth, .lastMonth:
            return (0..<30).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
                let dayExpenses = getExpensesForDate(date)
                return TrendDataPoint(
                    date: date,
                    value: dayExpenses.reduce(0) { $0 + $1.amount }
                )
            }.reversed()

        case .lastThreeMonths:
            return (0..<90).compactMap { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)
                return date.map { d in
                    let dayExpenses = getExpensesForDate(d)
                    return TrendDataPoint(
                        date: d,
                        value: dayExpenses.reduce(0) { $0 + $1.amount }
                    )
                }
            }.reversed()

        case .thisYear:
            return (0..<365).compactMap { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)
                return date.map { d in
                    let dayExpenses = getExpensesForDate(d)
                    return TrendDataPoint(
                        date: d,
                        value: dayExpenses.reduce(0) { $0 + $1.amount }
                    )
                }
            }.reversed()
        }
    }

    private func generateHeatmapData() -> [HeatmapDataPoint] {
        // Generate heatmap data for spending patterns
        let calendar = Calendar.current
        let now = Date()

        return (0..<365).compactMap { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)
            return date.map { d in
                let dayExpenses = getExpensesForDate(d)
                let totalAmount = dayExpenses.reduce(0) { $0 + $1.amount }
                return HeatmapDataPoint(
                    date: d,
                    value: totalAmount,
                    intensity: min(totalAmount / 1000.0, 1.0) // Normalize to 0-1
                )
            }
        }
    }

    private func getExpensesForDate(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenseViewModel.expenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: date)
        }
    }

    private func generateInsights() -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []

        // Spending pattern insights
        if let topSpendingDay = findTopSpendingDay() {
            insights.append(AnalyticsInsight(
                id: "top_spending_day",
                type: .pattern,
                title: L("highest_spending_day"),
                description: L("spent_most_on", formatDayOfWeek(topSpendingDay)),
                impact: .medium,
                actionable: true
            ))
        }

        // Budget insights
        if budgetEfficiency < 0.7 {
            insights.append(AnalyticsInsight(
                id: "budget_efficiency",
                type: .warning,
                title: L("budget_efficiency_low"),
                description: L("consider_reviewing_spending"),
                impact: .high,
                actionable: true
            ))
        }

        // Category insights
        if let growingCategory = findFastestGrowingCategory() {
            insights.append(AnalyticsInsight(
                id: "growing_category",
                type: .trend,
                title: L("category_growing_fast"),
                description: L("category_increased_spending", growingCategory),
                impact: .medium,
                actionable: true
            ))
        }

        return insights
    }

    // MARK: - Calculation Methods

    private func calculateSpendingTrend() -> TrendDirection {
        // Compare current period with previous period
        let currentAmount = expenseViewModel.totalFilteredAmount
        let previousAmount = calculatePreviousPeriodAmount()

        if currentAmount > previousAmount * 1.1 {
            return .up
        } else if currentAmount < previousAmount * 0.9 {
            return .down
        } else {
            return .neutral
        }
    }

    private func calculateAveragePerDay() -> Double {
        let days = getDaysInSelectedTimeframe()
        guard days > 0 else { return 0 }
        return expenseViewModel.totalFilteredAmount / Double(days)
    }

    private func calculateDailyAverageTrend() -> TrendDirection {
        let currentAverage = calculateAveragePerDay()
        let previousAverage = calculatePreviousPeriodDailyAverage()

        if currentAverage > previousAverage * 1.1 {
            return .up
        } else if currentAverage < previousAverage * 0.9 {
            return .down
        } else {
            return .neutral
        }
    }

    private var topCategoryName: String {
        let topCategory = expenseViewModel.categoryBreakdown.max(by: { $0.value < $1.value })
        return getCategoryName(topCategory?.key ?? "")
    }

    private var topCategoryAmount: Double {
        let topCategory = expenseViewModel.categoryBreakdown.max(by: { $0.value < $1.value })
        return topCategory?.value ?? 0
    }

    private var budgetEfficiency: Double {
        let monthlyLimit = settingsManager.monthlyLimit
        guard monthlyLimit > 0 else { return 1.0 }

        let monthlySpending = expenseViewModel.thisMonthExpenses.reduce(0) { $0 + $1.amount }
        return max(0, min(1, (monthlyLimit - monthlySpending) / monthlyLimit))
    }

    private var budgetEfficiencyLabel: String {
        if budgetEfficiency > 0.8 {
            return L("excellent")
        } else if budgetEfficiency > 0.6 {
            return L("good")
        } else if budgetEfficiency > 0.4 {
            return L("fair")
        } else {
            return L("needs_attention")
        }
    }

    private var budgetEfficiencyColor: Color {
        if budgetEfficiency > 0.8 {
            return .green
        } else if budgetEfficiency > 0.6 {
            return .blue
        } else if budgetEfficiency > 0.4 {
            return .orange
        } else {
            return .red
        }
    }

    private var budgetEfficiencyTrend: TrendDirection {
        // This would need historical data to calculate properly
        return .neutral
    }

    // Additional helper methods would be implemented here...
    private func calculateWeeklyChange() -> Double { return 0.0 }
    private func calculateMonthlyChange() -> Double { return 0.0 }
    private func calculateCategoryShift() -> Double { return 0.0 }
    private func calculateForecast() -> Double { return 0.0 }
    private func calculateSpendingDays() -> Int { return 0 }
    private func findLargestExpense() -> Double { return 0.0 }
    private func getDaysInSelectedTimeframe() -> Int { return 30 }
    private func calculatePreviousPeriodAmount() -> Double { return 0.0 }
    private func calculatePreviousPeriodDailyAverage() -> Double { return 0.0 }
    private func findTopSpendingDay() -> Date? { return nil }
    private func findFastestGrowingCategory() -> String? { return nil }
    private func getCategoryName(_ id: String) -> String { return "Category" }
    private func getCategoryColor(_ id: String) -> Color { return .blue }
    private func formatDayOfWeek(_ date: Date) -> String { return "Monday" }
    private func formatCurrency(_ amount: Double) -> String {
        return settingsManager.formatCurrency(amount)
    }
}

// MARK: - Supporting Types

enum AnalysisTimeframe: String, CaseIterable {
    case lastWeek = "lastWeek"
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case lastThreeMonths = "lastThreeMonths"
    case thisYear = "thisYear"

    var displayName: String {
        switch self {
        case .lastWeek:
            return L("last_week")
        case .thisMonth:
            return L("this_month")
        case .lastMonth:
            return L("last_month")
        case .lastThreeMonths:
            return L("last_three_months")
        case .thisYear:
            return L("this_year")
        }
    }
}

enum ChartType: String, CaseIterable {
    case pieChart = "pie"
    case barChart = "bar"
    case lineChart = "line"
    case heatmap = "heatmap"

    var displayName: String {
        switch self {
        case .pieChart:
            return L("pie_chart")
        case .barChart:
            return L("bar_chart")
        case .lineChart:
            return L("line_chart")
        case .heatmap:
            return L("heatmap")
        }
    }

    var iconName: String {
        switch self {
        case .pieChart:
            return "chart.pie.fill"
        case .barChart:
            return "chart.bar.fill"
        case .lineChart:
            return "chart.xyaxis.line"
        case .heatmap:
            return "grid"
        }
    }
}

enum AnalysisMetric: String, CaseIterable {
    case totalSpending = "totalSpending"
    case categoryBreakdown = "categoryBreakdown"
    case spendingTrend = "spendingTrend"
    case budgetEfficiency = "budgetEfficiency"

    var displayName: String {
        switch self {
        case .totalSpending:
            return L("total_spending")
        case .categoryBreakdown:
            return L("category_breakdown")
        case .spendingTrend:
            return L("spending_trend")
        case .budgetEfficiency:
            return L("budget_efficiency")
        }
    }
}

enum TrendDirection {
    case up, down, neutral

    var color: Color {
        switch self {
        case .up:
            return .red
        case .down:
            return .green
        case .neutral:
            return .gray
        }
    }

    var iconName: String {
        switch self {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .neutral:
            return "minus"
        }
    }
}

struct ChartDataPoint {
    let id: String
    let label: String
    let value: Double
    let color: Color
}

struct TrendDataPoint {
    let date: Date
    let value: Double
}

struct HeatmapDataPoint {
    let date: Date
    let value: Double
    let intensity: Double
}

struct AnalyticsInsight: Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let impact: InsightImpact
    let actionable: Bool

    enum InsightType {
        case pattern, warning, trend, recommendation
    }

    enum InsightImpact {
        case low, medium, high
    }
}

// MARK: - Supporting Views

struct TimeframeChip: View {
    let timeframe: AnalysisTimeframe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(timeframe.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .orange : .orange.opacity(0.2))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChartTypeButton: View {
    let chartType: ChartType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: chartType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .gray)

                Text(chartType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .frame(width: 80, height: 60)
            .themedCardBackground()
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .orange : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                        .foregroundColor(trend.color)

                    Text(trend == .neutral ? "" : "5%")
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .themedTextColor()

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption2)
                    .themedSecondaryTextColor()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCardBackground()
        .cornerRadius(12)
    }
}

struct TrendLineChart: View {
    let data: [TrendDataPoint]
    let timeframe: AnalysisTimeframe

    var body: some View {
        Chart(data, id: \.date) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Amount", point.value)
            )
            .foregroundStyle(.orange.gradient)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Amount", point.value)
            )
            .foregroundStyle(.orange.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct SpendingHeatmapChart: View {
    let data: [HeatmapDataPoint]
    let timeframe: AnalysisTimeframe

    var body: some View {
        // Simplified heatmap representation
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
            ForEach(data.prefix(49), id: \.date) { point in
                Rectangle()
                    .fill(.orange.opacity(point.intensity))
                    .frame(height: 20)
                    .cornerRadius(2)
            }
        }
        .padding()
    }
}

struct TrendInsightCard: View {
    let title: String
    let change: Double
    let description: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.orange)

                Spacer()

                Text("\(change > 0 ? "+" : "")\(Int(change))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(change > 0 ? .red : .green)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .themedTextColor()

            Text(description)
                .font(.caption2)
                .themedSecondaryTextColor()
        }
        .padding(12)
        .frame(width: 140, height: 80)
        .themedCardBackground()
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .themedTextColor()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption2)
                    .themedSecondaryTextColor()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCardBackground()
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let insight: AnalyticsInsight

    var body: some View {
        HStack(spacing: 12) {
            // Insight icon
            Image(systemName: iconForInsightType(insight.type))
                .font(.title3)
                .foregroundColor(colorForInsightType(insight.type))
                .frame(width: 40, height: 40)
                .background(colorForInsightType(insight.type).opacity(0.1))
                .cornerRadius(20)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Text(insight.description)
                    .font(.caption)
                    .themedSecondaryTextColor()
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            if insight.actionable {
                Button(L("action")) {
                    // Handle insight action
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .padding(16)
        .themedCardBackground()
        .cornerRadius(12)
    }

    private func iconForInsightType(_ type: AnalyticsInsight.InsightType) -> String {
        switch type {
        case .pattern:
            return "chart.line.uptrend.xyaxis"
        case .warning:
            return "exclamationmark.triangle"
        case .trend:
            return "arrow.up.right"
        case .recommendation:
            return "lightbulb"
        }
    }

    private func colorForInsightType(_ type: AnalyticsInsight.InsightType) -> Color {
        switch type {
        case .pattern:
            return .blue
        case .warning:
            return .red
        case .trend:
            return .orange
        case .recommendation:
            return .green
        }
    }
}

// MARK: - Filter Views

struct AnalysisFiltersView: View {
    @Binding var selectedTimeframe: AnalysisTimeframe
    @Binding var selectedMetrics: Set<AnalysisMetric>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(L("analysis_filters"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                // Timeframe selection
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("timeframe"))
                        .font(.headline)
                        .themedTextColor()

                    Picker(L("timeframe"), selection: $selectedTimeframe) {
                        ForEach(AnalysisTimeframe.allCases, id: \.rawValue) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Metrics selection
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("metrics_to_show"))
                        .font(.headline)
                        .themedTextColor()

                    ForEach(AnalysisMetric.allCases, id: \.rawValue) { metric in
                        Toggle(metric.displayName, isOn: Binding(
                            get: { selectedMetrics.contains(metric) },
                            set: { isOn in
                                if isOn {
                                    selectedMetrics.insert(metric)
                                } else {
                                    selectedMetrics.remove(metric)
                                }
                            }
                        ))
                        .themedTextColor()
                    }
                }

                Spacer()

                Button(L("apply_filters")) {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(L("export_analysis"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: L("export_pdf"),
                        description: L("detailed_report"),
                        icon: "doc.text"
                    ) {
                        // Export PDF
                    }

                    ExportOptionButton(
                        title: L("export_csv"),
                        description: L("raw_data"),
                        icon: "tablecells"
                    ) {
                        // Export CSV
                    }

                    ExportOptionButton(
                        title: L("share_insights"),
                        description: L("share_summary"),
                        icon: "square.and.arrow.up"
                    ) {
                        // Share insights
                    }
                }

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

struct ExportOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .themedTextColor()
                    .frame(width: 44, height: 44)
                    .themedCardBackground()
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .themedTextColor()

                    Text(description)
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .themedSecondaryTextColor()
            }
            .padding(16)
            .themedCardBackground()
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
#endif