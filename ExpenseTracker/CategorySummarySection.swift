//
//  CategorySummarySection.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct CategorySummarySection: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var expenseViewModel: ExpenseViewModel

    let expenses: [Expense]
    let timeRange: SummaryTimeRange
    let displayType: SummaryDisplayType

    @State private var selectedCategory: String? = nil
    @State private var showingCategoryDetail = false
    @State private var showingAllCategories = false
    @State private var expandedCategories: Set<String> = []

    private var categorySummaries: [CategorySummary] {
        generateCategorySummaries()
    }

    private var totalAmount: Double {
        categorySummaries.reduce(0) { $0 + $1.amount }
    }

    private var visibleSummaries: [CategorySummary] {
        let sorted = categorySummaries.sorted { first, second in
            switch displayType {
            case .amount:
                return first.amount > second.amount
            case .frequency:
                return first.expenseCount > second.expenseCount
            case .percentage:
                return first.percentage > second.percentage
            }
        }

        return showingAllCategories ? sorted : Array(sorted.prefix(5))
    }

    var body: some View {
        VStack(spacing: 16) {
            headerView

            if categorySummaries.isEmpty {
                emptyStateView
            } else {
                categoryListView
                footerView
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $showingCategoryDetail) {
            if let selectedCategory = selectedCategory {
                CategoryDetailBottomSheet(
                    categoryId: selectedCategory,
                    expenses: expenses,
                    month: Date()
                )
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.pie")
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(AppColors.primaryOrange)

                Text(L("category_summary"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Menu {
                    Button(L("by_amount")) {
                        // Handle display type change
                    }
                    Button(L("by_frequency")) {
                        // Handle display type change
                    }
                    Button(L("by_percentage")) {
                        // Handle display type change
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(displayType.displayName)
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryOrange)

                        Image(systemName: "chevron.down")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
            }

            HStack {
                Text(timeRange.displayName)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                Spacer()

                Text(formatCurrency(totalAmount))
                    .font(AppTypography.expenseAmount)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(L("no_expenses_in_period"))
                .font(AppTypography.bodyMedium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
        }
        .frame(height: 100)
    }

    private var categoryListView: some View {
        VStack(spacing: 8) {
            ForEach(visibleSummaries, id: \.categoryId) { summary in
                categorySummaryRow(summary)
            }
        }
    }

    private func categorySummaryRow(_ summary: CategorySummary) -> some View {
        VStack(spacing: 8) {
            Button(action: {
                selectedCategory = summary.categoryId
                showingCategoryDetail = true
            }) {
                HStack(spacing: 12) {
                    // Category icon/color indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(summary.color)
                        .frame(width: 8, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.categoryName)
                            .font(AppTypography.bodyMedium)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))
                            .lineLimit(1)

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "number")
                                    .font(AppTypography.labelSmall)
                                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                                Text("\(summary.expenseCount)")
                                    .font(AppTypography.labelSmall)
                                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                            }

                            if summary.budgetAmount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: summary.isOverBudget ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                        .font(AppTypography.labelSmall)
                                        .foregroundColor(summary.isOverBudget ? AppColors.primaryRed : AppColors.successGreen)

                                    Text(summary.budgetStatusText)
                                        .font(AppTypography.labelSmall)
                                        .foregroundColor(summary.isOverBudget ? AppColors.primaryRed : AppColors.successGreen)
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(summary.amount))
                            .font(AppTypography.expenseAmount)
                            .foregroundColor(ThemeColors.textColor(for: colorScheme))

                        Text("\(String(format: "%.1f", summary.percentage))%")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryOrange)
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedCategories.contains(summary.categoryId) {
                                expandedCategories.remove(summary.categoryId)
                            } else {
                                expandedCategories.insert(summary.categoryId)
                            }
                        }
                    }) {
                        Image(systemName: expandedCategories.contains(summary.categoryId) ? "chevron.up" : "chevron.down")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Progress bar
            ProgressView(value: summary.percentage / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: summary.color))
                .scaleEffect(x: 1, y: 0.5, anchor: .center)

            // Expanded subcategory details
            if expandedCategories.contains(summary.categoryId) && !summary.subCategories.isEmpty {
                subcategoryDetailsView(for: summary)
            }
        }
        .padding(.vertical, 8)
    }

    private func subcategoryDetailsView(for summary: CategorySummary) -> some View {
        VStack(spacing: 6) {
            ForEach(summary.subCategories, id: \.subCategoryId) { subCategory in
                HStack {
                    Circle()
                        .fill(summary.color.opacity(0.6))
                        .frame(width: 6, height: 6)

                    Text(subCategory.subCategoryName)
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Spacer()

                    Text(formatCurrency(subCategory.amount))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text("(\(subCategory.expenseCount))")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .padding(.leading, 16)
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 8)
        .background(summary.color.opacity(0.05))
        .cornerRadius(8)
    }

    private var footerView: some View {
        VStack(spacing: 12) {
            if !showingAllCategories && categorySummaries.count > 5 {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAllCategories = true
                    }
                }) {
                    HStack {
                        Text(L("show_all_categories", categorySummaries.count))
                            .font(AppTypography.buttonText)
                            .foregroundColor(AppColors.primaryOrange)

                        Image(systemName: "chevron.down")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
            } else if showingAllCategories {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingAllCategories = false
                    }
                }) {
                    HStack {
                        Text(L("show_less"))
                            .font(AppTypography.buttonText)
                            .foregroundColor(AppColors.primaryOrange)

                        Image(systemName: "chevron.up")
                            .font(AppTypography.labelMedium)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
            }

            Divider()
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme).opacity(0.3))

            statisticsRow
        }
    }

    private var statisticsRow: some View {
        HStack {
            statisticsItem(
                title: L("categories"),
                value: "\(categorySummaries.count)",
                icon: "grid.circle"
            )

            Divider()
                .frame(height: 30)

            statisticsItem(
                title: L("avg_per_category"),
                value: formatCurrency(categorySummaries.isEmpty ? 0 : totalAmount / Double(categorySummaries.count)),
                icon: "chart.bar"
            )

            Divider()
                .frame(height: 30)

            statisticsItem(
                title: L("top_category"),
                value: topCategoryPercentage,
                icon: "crown"
            )
        }
    }

    private func statisticsItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.primaryOrange)

            Text(title)
                .font(AppTypography.labelSmall)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                .multilineTextAlignment(.center)

            Text(value)
                .font(AppTypography.labelMedium)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties

    private var topCategoryPercentage: String {
        guard let topCategory = categorySummaries.max(by: { $0.percentage < $1.percentage }) else {
            return "0%"
        }
        return String(format: "%.1f%%", topCategory.percentage)
    }

    // MARK: - Helper Functions

    private func generateCategorySummaries() -> [CategorySummary] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date

        switch timeRange {
        case .thisMonth:
            startDate = calendar.dateInterval(of: .month, for: endDate)?.start ?? endDate
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            startDate = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? endDate
        case .last30Days:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .last90Days:
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .thisYear:
            startDate = calendar.dateInterval(of: .year, for: endDate)?.start ?? endDate
        case .custom(let start, _):
            startDate = start
        }

        let filteredExpenses = expenses.filter { expense in
            expense.date >= startDate && expense.date <= endDate
        }

        let groupedByCategory = Dictionary(grouping: filteredExpenses) { $0.categoryId }
        let totalExpenseAmount = filteredExpenses.reduce(0) { $0 + $1.amount }

        return groupedByCategory.compactMap { categoryId, categoryExpenses in
            let amount = categoryExpenses.reduce(0) { $0 + $1.amount }
            let percentage = totalExpenseAmount > 0 ? (amount / totalExpenseAmount) * 100 : 0

            // Generate subcategory breakdown
            let subCategoryBreakdown = Dictionary(grouping: categoryExpenses) { $0.subCategoryId }
            let subCategories = subCategoryBreakdown.map { subCategoryId, subCategoryExpenses in
                SubCategorySummary(
                    subCategoryId: subCategoryId,
                    subCategoryName: getSubCategoryName(subCategoryId),
                    amount: subCategoryExpenses.reduce(0) { $0 + $1.amount },
                    expenseCount: subCategoryExpenses.count
                )
            }.sorted { $0.amount > $1.amount }

            // Get budget information (this would come from budget settings)
            let budgetAmount = getBudgetAmount(for: categoryId)

            return CategorySummary(
                categoryId: categoryId,
                categoryName: getCategoryName(categoryId),
                amount: amount,
                percentage: percentage,
                expenseCount: categoryExpenses.count,
                color: getCategoryColor(categoryId),
                budgetAmount: budgetAmount,
                subCategories: subCategories
            )
        }
    }

    private func getCategoryName(_ categoryId: String) -> String {
        return expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private func getSubCategoryName(_ subCategoryId: String) -> String {
        return expenseViewModel.availableSubCategories.first { $0.id == subCategoryId }?.name ?? L("unknown_subcategory")
    }

    private func getCategoryColor(_ categoryId: String) -> Color {
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

        let hash = categoryId.hashValue
        return colors[abs(hash) % colors.count]
    }

    private func getBudgetAmount(for categoryId: String) -> Double {
        // This would come from budget settings or planning view model
        return 0 // Placeholder
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

struct CategorySummary {
    let categoryId: String
    let categoryName: String
    let amount: Double
    let percentage: Double
    let expenseCount: Int
    let color: Color
    let budgetAmount: Double
    let subCategories: [SubCategorySummary]

    var isOverBudget: Bool {
        budgetAmount > 0 && amount > budgetAmount
    }

    var budgetUsagePercentage: Double {
        guard budgetAmount > 0 else { return 0 }
        return (amount / budgetAmount) * 100
    }

    var budgetStatusText: String {
        guard budgetAmount > 0 else { return "" }
        return String(format: "%.0f%%", budgetUsagePercentage)
    }
}

struct SubCategorySummary {
    let subCategoryId: String
    let subCategoryName: String
    let amount: Double
    let expenseCount: Int
}

enum SummaryTimeRange {
    case thisMonth
    case lastMonth
    case last30Days
    case last90Days
    case thisYear
    case custom(start: Date, end: Date)

    var displayName: String {
        switch self {
        case .thisMonth:
            return L("this_month")
        case .lastMonth:
            return L("last_month")
        case .last30Days:
            return L("last_30_days")
        case .last90Days:
            return L("last_90_days")
        case .thisYear:
            return L("this_year")
        case .custom(let start, let end):
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("MMM d")
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

enum SummaryDisplayType: String, CaseIterable {
    case amount = "amount"
    case frequency = "frequency"
    case percentage = "percentage"

    var displayName: String {
        switch self {
        case .amount:
            return L("by_amount")
        case .frequency:
            return L("by_frequency")
        case .percentage:
            return L("by_percentage")
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CategorySummarySection_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 500, categoryId: "food", subCategoryId: "restaurants", description: "Dinner"),
            Expense(amount: 300, categoryId: "transport", subCategoryId: "fuel", description: "Gas"),
            Expense(amount: 200, categoryId: "shopping", subCategoryId: "clothes", description: "Shirt"),
            Expense(amount: 150, categoryId: "food", subCategoryId: "groceries", description: "Groceries")
        ]

        CategorySummarySection(
            expenseViewModel: ExpenseViewModel.preview,
            expenses: mockExpenses,
            timeRange: .thisMonth,
            displayType: .amount
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif