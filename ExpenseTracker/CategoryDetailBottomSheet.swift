//
//  CategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct CategoryDetailBottomSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel = ExpenseViewModel()

    let categoryId: String
    let expenses: [Expense]
    let month: Date

    @State private var selectedTimeRange: DetailTimeRange = .thisMonth
    @State private var showingExpensesList = false
    @State private var showingSubcategoryDetail = false
    @State private var selectedSubcategory: String? = nil

    private var categoryExpenses: [Expense] {
        let calendar = Calendar.current
        let startDate: Date
        let endDate: Date

        switch selectedTimeRange {
        case .thisMonth:
            let monthInterval = calendar.dateInterval(of: .month, for: month) ?? DateInterval(start: month, end: month)
            startDate = monthInterval.start
            endDate = monthInterval.end
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: month) ?? month
            let monthInterval = calendar.dateInterval(of: .month, for: lastMonth) ?? DateInterval(start: lastMonth, end: lastMonth)
            startDate = monthInterval.start
            endDate = monthInterval.end
        case .last30Days:
            endDate = Date()
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        case .last90Days:
            endDate = Date()
            startDate = calendar.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        case .thisYear:
            let yearInterval = calendar.dateInterval(of: .year, for: month) ?? DateInterval(start: month, end: month)
            startDate = yearInterval.start
            endDate = yearInterval.end
        }

        return expenses.filter { expense in
            expense.categoryId == categoryId &&
            expense.date >= startDate &&
            expense.date < endDate
        }
    }

    private var categoryName: String {
        expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private var totalAmount: Double {
        categoryExpenses.reduce(0) { $0 + $1.amount }
    }

    private var subcategoryBreakdown: [SubcategoryData] {
        let grouped = Dictionary(grouping: categoryExpenses) { $0.subCategoryId }
        return grouped.map { subCategoryId, subExpenses in
            SubcategoryData(
                id: subCategoryId,
                name: getSubcategoryName(subCategoryId),
                amount: subExpenses.reduce(0) { $0 + $1.amount },
                percentage: totalAmount > 0 ? (subExpenses.reduce(0) { $0 + $1.amount } / totalAmount) * 100 : 0,
                expenseCount: subExpenses.count,
                color: getSubcategoryColor(subCategoryId)
            )
        }.sorted { $0.amount > $1.amount }
    }

    private var dailySpendingData: [DailySpendingData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: categoryExpenses) { expense in
            calendar.startOfDay(for: expense.date)
        }

        return grouped.map { date, dayExpenses in
            DailySpendingData(
                date: date,
                amount: dayExpenses.reduce(0) { $0 + $1.amount },
                expenseCount: dayExpenses.count
            )
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    overviewSection
                    chartSection
                    subcategorySection
                    quickActionsSection
                }
                .padding()
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationTitle(categoryName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExpensesList) {
            MonthlyExpensesView(
                expenses: categoryExpenses,
                date: month
            )
        }
        .sheet(isPresented: $showingSubcategoryDetail) {
            if let selectedSubcategory = selectedSubcategory {
                SubCategoryDetailBottomSheet(
                    categoryId: categoryId,
                    subCategoryId: selectedSubcategory,
                    expenses: expenses,
                    month: month
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(getCategoryColor())
                    .frame(width: 20, height: 20)

                Text(categoryName)
                    .font(AppTypography.titleMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                timeRangePicker
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("total_spent"))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(formatCurrency(totalAmount))
                        .font(AppTypography.expenseAmountLarge)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(L("transactions"))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text("\(categoryExpenses.count)")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private var timeRangePicker: some View {
        Menu {
            ForEach(DetailTimeRange.allCases, id: \.self) { range in
                Button(range.displayName) {
                    selectedTimeRange = range
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTimeRange.displayName)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.primaryOrange)

                Image(systemName: "chevron.down")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(AppColors.primaryOrange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryOrange.opacity(0.1))
            )
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("overview"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                overviewCard(
                    title: L("avg_per_transaction"),
                    value: formatCurrency(categoryExpenses.isEmpty ? 0 : totalAmount / Double(categoryExpenses.count)),
                    icon: "chart.bar",
                    color: AppColors.successGreen
                )

                overviewCard(
                    title: L("highest_expense"),
                    value: formatCurrency(categoryExpenses.map { $0.amount }.max() ?? 0),
                    icon: "arrow.up.circle",
                    color: AppColors.primaryRed
                )

                overviewCard(
                    title: L("most_frequent_day"),
                    value: mostFrequentDay,
                    icon: "calendar",
                    color: .blue
                )

                overviewCard(
                    title: L("subcategories"),
                    value: "\(subcategoryBreakdown.count)",
                    icon: "grid",
                    color: AppColors.primaryOrange
                )
            }
        }
    }

    private func overviewCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(color)

                Spacer()
            }

            Text(title)
                .font(AppTypography.labelMedium)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            Text(value)
                .font(AppTypography.bodyLarge)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))
        }
        .padding(12)
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("spending_trend"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            if dailySpendingData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("no_data_available"))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .frame(height: 150)
            } else {
                Chart(dailySpendingData, id: \.date) { data in
                    BarMark(
                        x: .value(L("date"), data.date),
                        y: .value(L("amount"), data.amount)
                    )
                    .foregroundStyle(AppColors.primaryGradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedTimeRange.axisStride)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(AppTypography.labelSmall)
                            .foregroundStyle(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private var subcategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("subcategories"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                if subcategoryBreakdown.count > 3 {
                    Button(L("view_all")) {
                        // Handle view all subcategories
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.primaryOrange)
                }
            }

            if subcategoryBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("no_subcategories"))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .frame(height: 80)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(subcategoryBreakdown.prefix(5)), id: \.id) { subcategory in
                        subcategoryRow(subcategory)
                    }
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private func subcategoryRow(_ subcategory: SubcategoryData) -> some View {
        Button(action: {
            selectedSubcategory = subcategory.id
            showingSubcategoryDetail = true
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(subcategory.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subcategory.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text("\(subcategory.expenseCount) \(L("transactions"))")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatCurrency(subcategory.amount))
                        .font(AppTypography.expenseAmount)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text("\(String(format: "%.1f", subcategory.percentage))%")
                        .font(AppTypography.labelSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }

                Image(systemName: "chevron.right")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                actionButton(
                    title: L("view_expenses"),
                    icon: "list.bullet",
                    color: AppColors.primaryOrange
                ) {
                    showingExpensesList = true
                }

                actionButton(
                    title: L("add_expense"),
                    icon: "plus.circle",
                    color: AppColors.successGreen
                ) {
                    // Handle add expense
                    expenseViewModel.prepareNewExpenseForm()
                    expenseViewModel.newExpenseForm.categoryId = categoryId
                    expenseViewModel.showingAddExpense = true
                }
            }

            HStack {
                actionButton(
                    title: L("set_budget"),
                    icon: "target",
                    color: .blue
                ) {
                    // Handle set budget
                }

                actionButton(
                    title: L("export_data"),
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    // Handle export
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(.white)

                Text(title)
                    .font(AppTypography.labelMedium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Computed Properties

    private var mostFrequentDay: String {
        let calendar = Calendar.current
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        let dayFrequency = Dictionary(grouping: categoryExpenses) { expense in
            calendar.component(.weekday, from: expense.date)
        }

        guard let mostFrequentWeekday = dayFrequency.max(by: { $0.value.count < $1.value.count })?.key else {
            return L("none")
        }

        // Convert weekday number to name
        let date = calendar.date(bySetting: .weekday, value: mostFrequentWeekday, of: Date()) ?? Date()
        return dayFormatter.string(from: date)
    }

    // MARK: - Helper Functions

    private func getSubcategoryName(_ subCategoryId: String) -> String {
        expenseViewModel.availableSubCategories.first { $0.id == subCategoryId }?.name ?? L("unknown_subcategory")
    }

    private func getCategoryColor() -> Color {
        AppColors.primaryOrange // This would come from category settings
    }

    private func getSubcategoryColor(_ subCategoryId: String) -> Color {
        let colors: [Color] = [
            AppColors.primaryOrange,
            AppColors.primaryRed,
            AppColors.successGreen,
            .blue,
            .purple,
            .pink
        ]
        let hash = subCategoryId.hashValue
        return colors[abs(hash) % colors.count]
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

struct SubcategoryData {
    let id: String
    let name: String
    let amount: Double
    let percentage: Double
    let expenseCount: Int
    let color: Color
}

struct DailySpendingData {
    let date: Date
    let amount: Double
    let expenseCount: Int
}

enum DetailTimeRange: String, CaseIterable {
    case thisMonth = "thisMonth"
    case lastMonth = "lastMonth"
    case last30Days = "last30Days"
    case last90Days = "last90Days"
    case thisYear = "thisYear"

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
        }
    }

    var axisStride: Int {
        switch self {
        case .thisMonth, .lastMonth:
            return 7 // Weekly
        case .last30Days:
            return 5 // Every 5 days
        case .last90Days:
            return 15 // Every 15 days
        case .thisYear:
            return 30 // Monthly
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 50, categoryId: "food", subCategoryId: "restaurants", description: "Lunch"),
            Expense(amount: 120, categoryId: "food", subCategoryId: "groceries", description: "Groceries"),
            Expense(amount: 25, categoryId: "food", subCategoryId: "restaurants", description: "Coffee")
        ]

        CategoryDetailBottomSheet(
            categoryId: "food",
            expenses: mockExpenses,
            month: Date()
        )
    }
}
#endif