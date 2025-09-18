//
//  CategoryDistributionChart.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

/// Enhanced category distribution chart component using native SwiftUI Charts
/// Provides comprehensive expense distribution visualization with interactive features
struct CategoryDistributionChart: View {

    // MARK: - Properties

    let categoryData: [CategoryExpenseData]
    let totalAmount: Double
    let showPercentages: Bool
    let showLegend: Bool
    let chartSize: CGFloat
    let animationDuration: Double
    let onCategoryTap: ((CategoryExpenseData) -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategory: CategoryExpenseData?
    @State private var showingDetails = false

    // MARK: - Initializers

    /// Creates a basic category distribution chart
    /// - Parameters:
    ///   - categoryData: Array of category expense data
    ///   - totalAmount: Total expense amount
    init(
        categoryData: [CategoryExpenseData],
        totalAmount: Double
    ) {
        self.categoryData = categoryData
        self.totalAmount = totalAmount
        self.showPercentages = true
        self.showLegend = true
        self.chartSize = 200
        self.animationDuration = 1.0
        self.onCategoryTap = nil
    }

    /// Creates a fully customizable category distribution chart
    /// - Parameters:
    ///   - categoryData: Array of category expense data
    ///   - totalAmount: Total expense amount
    ///   - showPercentages: Whether to show percentage values
    ///   - showLegend: Whether to show legend below chart
    ///   - chartSize: Size of the chart
    ///   - animationDuration: Animation duration for chart appearance
    ///   - onCategoryTap: Callback when category is tapped
    init(
        categoryData: [CategoryExpenseData],
        totalAmount: Double,
        showPercentages: Bool = true,
        showLegend: Bool = true,
        chartSize: CGFloat = 200,
        animationDuration: Double = 1.0,
        onCategoryTap: ((CategoryExpenseData) -> Void)? = nil
    ) {
        self.categoryData = categoryData
        self.totalAmount = totalAmount
        self.showPercentages = showPercentages
        self.showLegend = showLegend
        self.chartSize = chartSize
        self.animationDuration = animationDuration
        self.onCategoryTap = onCategoryTap
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Chart title and total
            VStack(spacing: 4) {
                Text(L("expense_distribution"))
                    .font(.headline.bold())
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text(formatCurrency(totalAmount))
                    .font(.title2.bold())
                    .foregroundColor(AppColors.primaryOrange)
            }

            // Pie chart
            ZStack {
                Chart(categoryData, id: \.categoryId) { data in
                    SectorMark(
                        angle: .value(L("amount"), data.amount),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .foregroundStyle(data.color)
                    .opacity(selectedCategory == nil || selectedCategory?.categoryId == data.categoryId ? 1.0 : 0.5)
                }
                .frame(width: chartSize, height: chartSize)
                .chartLegend(.hidden)
                .onTapGesture { location in
                    handleChartTap(at: location)
                }

                // Center content
                VStack(spacing: 4) {
                    if let selected = selectedCategory {
                        Text(selected.categoryName)
                            .font(.caption.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                            .multilineTextAlignment(.center)

                        Text(formatCurrency(selected.amount))
                            .font(.subheadline.bold())
                            .foregroundColor(selected.color)

                        if showPercentages {
                            Text("\(Int(selected.percentage))%")
                                .font(.caption)
                                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                        }
                    } else {
                        Text(L("total"))
                            .font(.caption)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                        Text(formatCurrency(totalAmount))
                            .font(.subheadline.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))

                        Text("\(categoryData.count) \(L("categories"))")
                            .font(.caption2)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
            }

            // Legend
            if showLegend {
                legendView
            }

            // Selected category details
            if let selected = selectedCategory {
                selectedCategoryDetails(selected)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        .sheet(isPresented: $showingDetails) {
            if let category = selectedCategory {
                CategoryDetailSheet(categoryData: category)
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var legendView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
            ForEach(categoryData.prefix(6), id: \.categoryId) { data in
                HStack(spacing: 8) {
                    Circle()
                        .fill(data.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.categoryName)
                            .font(.caption)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(formatCurrency(data.amount))
                                .font(.caption2)
                                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                            if showPercentages {
                                Text("(\(Int(data.percentage))%)")
                                    .font(.caption2)
                                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                            }
                        }
                    }

                    Spacer()
                }
                .onTapGesture {
                    handleCategoryTap(data)
                }
            }

            // Show more indicator if there are more than 6 categories
            if categoryData.count > 6 {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 12, height: 12)

                    Text(L("and_more_categories", categoryData.count - 6))
                        .font(.caption)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func selectedCategoryDetails(_ category: CategoryExpenseData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.categoryName)
                        .font(.headline)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text(L("category_details"))
                        .font(.caption)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }

                Spacer()

                Button(L("view_details")) {
                    showingDetails = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(category.color.opacity(0.2))
                .foregroundColor(category.color)
                .clipShape(Capsule())
            }

            // Statistics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("amount"))
                        .font(.caption)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    Text(formatCurrency(category.amount))
                        .font(.subheadline.bold())
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text(L("percentage"))
                        .font(.caption)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    Text("\(String(format: "%.1f", category.percentage))%")
                        .font(.subheadline.bold())
                        .foregroundColor(category.color)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("expenses"))
                        .font(.caption)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    Text("\(category.expenseCount)")
                        .font(.subheadline.bold())
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }
            }

            Button {
                selectedCategory = nil
            } label: {
                Text(L("clear_selection"))
                    .font(.caption)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Methods

    private func handleChartTap(at location: CGPoint) {
        // Simple approximation - in a real implementation, you'd calculate the angle
        // and determine which sector was tapped based on the chart geometry
        if !categoryData.isEmpty {
            let index = min(Int(location.x / chartSize * Double(categoryData.count)), categoryData.count - 1)
            if index >= 0 && index < categoryData.count {
                selectedCategory = selectedCategory?.categoryId == categoryData[index].categoryId ? nil : categoryData[index]
            }
        }
    }

    private func handleCategoryTap(_ category: CategoryExpenseData) {
        selectedCategory = selectedCategory?.categoryId == category.categoryId ? nil : category
        onCategoryTap?(category)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY" // Should come from settings
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺\(Int(amount))"
    }
}

// MARK: - Data Model

/// Data structure for category expense information in charts
struct CategoryExpenseData: Identifiable, Equatable {
    let id = UUID()
    let categoryId: String
    let categoryName: String
    let amount: Double
    let percentage: Double
    let color: Color
    let iconName: String
    let expenseCount: Int
    let budget: Double?
    let trend: Double? // Percentage change from previous period

    static func == (lhs: CategoryExpenseData, rhs: CategoryExpenseData) -> Bool {
        return lhs.categoryId == rhs.categoryId
    }
}

// MARK: - Category Detail Sheet

struct CategoryDetailSheet: View {
    let categoryData: CategoryExpenseData

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(categoryData.color.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: categoryData.iconName)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(categoryData.color)
                        }

                        Text(categoryData.categoryName)
                            .font(.title.bold())
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))

                        Text(formatCurrency(categoryData.amount))
                            .font(.title2.bold())
                            .foregroundColor(categoryData.color)
                    }
                    .padding(.top, 20)

                    // Statistics
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            title: L("total_spent"),
                            value: formatCurrency(categoryData.amount),
                            icon: "dollarsign.circle.fill",
                            color: categoryData.color
                        )

                        StatCard(
                            title: L("percentage_of_total"),
                            value: "\(String(format: "%.1f", categoryData.percentage))%",
                            icon: "chart.pie.fill",
                            color: .blue
                        )

                        StatCard(
                            title: L("number_of_expenses"),
                            value: "\(categoryData.expenseCount)",
                            icon: "list.number",
                            color: .green
                        )

                        if let budget = categoryData.budget {
                            StatCard(
                                title: L("budget"),
                                value: formatCurrency(budget),
                                icon: "target",
                                color: categoryData.amount > budget ? .red : .green
                            )
                        }
                    }

                    if let trend = categoryData.trend {
                        TrendCard(trend: trend, categoryColor: categoryData.color)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(L("category_details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺\(Int(amount))"
    }
}

// MARK: - Trend Card Component

struct TrendCard: View {
    let trend: Double
    let categoryColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Image(systemName: trendIcon)
                .foregroundColor(trendColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(L("trend_vs_last_period"))
                    .font(.subheadline)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text(trendText)
                    .font(.caption)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            Spacer()

            Text("\(trend > 0 ? "+" : "")\(String(format: "%.1f", trend))%")
                .font(.headline.bold())
                .foregroundColor(trendColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ThemeColors.cardBackgroundColor(for: colorScheme))
        )
    }

    private var trendIcon: String {
        if abs(trend) < 5 {
            return "minus.circle.fill"
        } else if trend > 0 {
            return "arrow.up.circle.fill"
        } else {
            return "arrow.down.circle.fill"
        }
    }

    private var trendColor: Color {
        if abs(trend) < 5 {
            return .gray
        } else if trend > 0 {
            return .red
        } else {
            return .green
        }
    }

    private var trendText: String {
        if abs(trend) < 5 {
            return L("spending_stable")
        } else if trend > 0 {
            return L("spending_increased")
        } else {
            return L("spending_decreased")
        }
    }
}

// MARK: - Convenience Initializers

extension CategoryDistributionChart {
    /// Creates a compact category distribution chart
    static func compact(
        categoryData: [CategoryExpenseData],
        totalAmount: Double
    ) -> CategoryDistributionChart {
        return CategoryDistributionChart(
            categoryData: categoryData,
            totalAmount: totalAmount,
            showPercentages: false,
            showLegend: false,
            chartSize: 120
        )
    }

    /// Creates a detailed category distribution chart with interactive features
    static func detailed(
        categoryData: [CategoryExpenseData],
        totalAmount: Double,
        onCategoryTap: @escaping (CategoryExpenseData) -> Void
    ) -> CategoryDistributionChart {
        return CategoryDistributionChart(
            categoryData: categoryData,
            totalAmount: totalAmount,
            showPercentages: true,
            showLegend: true,
            chartSize: 240,
            onCategoryTap: onCategoryTap
        )
    }
}

// MARK: - Array Extensions

extension Array where Element == CategoryExpenseData {
    /// Sorts categories by amount (descending)
    var sortedByAmount: [CategoryExpenseData] {
        return sorted { $0.amount > $1.amount }
    }

    /// Filters categories above a certain threshold percentage
    func above(threshold: Double) -> [CategoryExpenseData] {
        return filter { $0.percentage >= threshold }
    }

    /// Groups small categories into "Other" category
    func groupingSmallCategories(threshold: Double = 5.0) -> [CategoryExpenseData] {
        let major = above(threshold: threshold)
        let minor = filter { $0.percentage < threshold }

        if minor.isEmpty {
            return major
        }

        let otherAmount = minor.reduce(0) { $0 + $1.amount }
        let otherPercentage = minor.reduce(0) { $0 + $1.percentage }
        let otherCount = minor.reduce(0) { $0 + $1.expenseCount }

        let otherCategory = CategoryExpenseData(
            categoryId: "other",
            categoryName: L("other_categories"),
            amount: otherAmount,
            percentage: otherPercentage,
            color: .gray,
            iconName: "ellipsis.circle.fill",
            expenseCount: otherCount,
            budget: nil,
            trend: nil
        )

        return major + [otherCategory]
    }
}

// MARK: - Preview Provider

#if DEBUG
struct CategoryDistributionChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Basic chart
                CategoryDistributionChart(
                    categoryData: CategoryExpenseData.mockData(),
                    totalAmount: 1250.0
                )

                // Compact chart
                CategoryDistributionChart.compact(
                    categoryData: CategoryExpenseData.mockData(),
                    totalAmount: 1250.0
                )

                // Detailed chart
                CategoryDistributionChart.detailed(
                    categoryData: CategoryExpenseData.mockData(),
                    totalAmount: 1250.0,
                    onCategoryTap: { _ in }
                )
            }
            .padding()
        }
        .background(ThemeColors.backgroundColor(for: .dark))
        .preferredColorScheme(.dark)
        .previewDisplayName("Category Distribution Charts")
    }
}

// MARK: - Mock Data

extension CategoryExpenseData {
    static func mockData() -> [CategoryExpenseData] {
        return [
            CategoryExpenseData(
                categoryId: "food",
                categoryName: "Food & Drinks",
                amount: 450.0,
                percentage: 36.0,
                color: .red,
                iconName: "fork.knife",
                expenseCount: 23,
                budget: 500.0,
                trend: 12.5
            ),
            CategoryExpenseData(
                categoryId: "transportation",
                categoryName: "Transportation",
                amount: 300.0,
                percentage: 24.0,
                color: .blue,
                iconName: "car.fill",
                expenseCount: 8,
                budget: 350.0,
                trend: -5.2
            ),
            CategoryExpenseData(
                categoryId: "entertainment",
                categoryName: "Entertainment",
                amount: 200.0,
                percentage: 16.0,
                color: .purple,
                iconName: "tv.fill",
                expenseCount: 12,
                budget: 150.0,
                trend: 33.3
            ),
            CategoryExpenseData(
                categoryId: "shopping",
                categoryName: "Shopping",
                amount: 180.0,
                percentage: 14.4,
                color: .pink,
                iconName: "bag.fill",
                expenseCount: 6,
                budget: 200.0,
                trend: -10.0
            ),
            CategoryExpenseData(
                categoryId: "utilities",
                categoryName: "Utilities",
                amount: 120.0,
                percentage: 9.6,
                color: .yellow,
                iconName: "bolt.fill",
                expenseCount: 4,
                budget: 120.0,
                trend: 0.0
            )
        ]
    }
}
#endif