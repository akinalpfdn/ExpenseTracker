//
//  SubCategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android SubCategoryDetailBottomSheet.kt
//

import SwiftUI

struct SubCategoryDetailBottomSheet: View {
    let subCategoryData: SubCategoryAnalysisData
    let defaultCurrency: String
    let isDarkTheme: Bool
    let viewModel: ExpenseViewModel
    let selectedMonth: Date
    let selectedFilterType: ExpenseFilterType

    @State private var selectedSortOption: SortOption = .amountDesc
    @State private var showSortMenu = false

    init(
        subCategoryData: SubCategoryAnalysisData,
        defaultCurrency: String = "₺",
        isDarkTheme: Bool = true,
        viewModel: ExpenseViewModel,
        selectedMonth: Date,
        selectedFilterType: ExpenseFilterType = .all
    ) {
        self.subCategoryData = subCategoryData
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.viewModel = viewModel
        self.selectedMonth = selectedMonth
        self.selectedFilterType = selectedFilterType
    }

    var body: some View {
        VStack(spacing: 16) {
            headerSection
            summarySection
            sortSection
            expensesList
        }
        .padding(16)
    }
}

// MARK: - Computed Properties
extension SubCategoryDetailBottomSheet {
    private var sortedExpenses: [Expense] {
        switch selectedSortOption {
        case .amountDesc:
            return subCategoryData.expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .amountAsc:
            return subCategoryData.expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .dateDesc:
            return subCategoryData.expenses.sorted { $0.date > $1.date }
        case .dateAsc:
            return subCategoryData.expenses.sorted { $0.date < $1.date }
        case .nameAsc:
            return subCategoryData.expenses.sorted { $0.description.lowercased() < $1.description.lowercased() }
        case .nameDesc:
            return subCategoryData.expenses.sorted { $0.description.lowercased() > $1.description.lowercased() }
        }
    }

    private var comparison: CategoryComparison {
        calculateSubCategoryComparison(
            viewModel: viewModel,
            selectedMonth: selectedMonth,
            subCategoryId: subCategoryData.subCategory.id,
            filterType: selectedFilterType
        )
    }

    private var averageAmount: Double {
        guard subCategoryData.expenseCount > 0 else { return 0.0 }
        return subCategoryData.totalAmount / Double(subCategoryData.expenseCount)
    }
}

// MARK: - View Components
extension SubCategoryDetailBottomSheet {
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            categoryIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(subCategoryData.subCategory.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .lineLimit(1)

                Text("\("parent_category".localized): \(subCategoryData.parentCategory.name)")
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                comparisonIndicators
            }

            Spacer()
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(subCategoryData.parentCategory.getColor().opacity(0.2))
                .frame(width: 48, height: 48)

            Image(systemName: subCategoryData.parentCategory.getIcon())
                .foregroundColor(subCategoryData.parentCategory.getColor())
                .font(.system(size: 24))
        }
    }

    private var comparisonIndicators: some View {
        VStack(alignment: .leading, spacing: 8) {
            SubCategoryComparisonIndicator(
                amount: comparison.vsLastMonth,
                currency: defaultCurrency,
                label: "vs_previous_month".localized,
                isDarkTheme: isDarkTheme
            )

            SubCategoryComparisonIndicator(
                amount: comparison.vsAverage,
                currency: defaultCurrency,
                label: "vs_6_month_average".localized,
                isDarkTheme: isDarkTheme
            )
        }
        .padding(.top, 8)
    }

    private var summarySection: some View {
        HStack(spacing: 0) {
            summaryItem(
                title: "total_amount".localized,
                value: "\(defaultCurrency) \(NumberFormatter.formatAmount(subCategoryData.totalAmount))"
            )

            summaryDivider

            summaryItem(
                title: "expense_count".localized,
                value: "\(subCategoryData.expenseCount)"
            )

            summaryDivider

            summaryItem(
                title: "average".localized,
                value: "\(defaultCurrency) \(NumberFormatter.formatAmount(averageAmount))"
            )
        }
        .padding(16)
        .background(subCategoryData.parentCategory.getColor().opacity(0.1))
        .cornerRadius(12)
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3))
            .frame(width: 1, height: 40)
    }

    private var sortSection: some View {
        HStack {
            Text("expenses".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            sortButton
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedSortOption = option
                }) {
                    Text(option.displayName)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16))

                Text(selectedSortOption.displayName)
                    .font(.system(size: 14))

                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
            }
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
    }

    private var expensesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(sortedExpenses, id: \.id) { expense in
                    SubCategoryExpenseItem(
                        expense: expense,
                        defaultCurrency: defaultCurrency,
                        isDarkTheme: isDarkTheme,
                        categoryColor: subCategoryData.parentCategory.getColor()
                    )
                }
            }
        }
    }
}

struct SubCategoryExpenseItem: View {
    let expense: Expense
    let defaultCurrency: String
    let isDarkTheme: Bool
    let categoryColor: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            colorIndicator

            expenseDetails

            Spacer()

            amountSection
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
    }
}

// MARK: - SubCategory Expense Item Components
extension SubCategoryExpenseItem {
    private var colorIndicator: some View {
        Circle()
            .fill(categoryColor)
            .frame(width: 4, height: 4)
    }

    private var expenseDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(expense.description.isEmpty ? "no_description".localized : expense.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .lineLimit(1)

            Text(expense.date, style: .date)
                .font(.system(size: 12))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            if expense.recurrenceType != .NONE {
                Text("\("recurring_label".localized): \(expense.recurrenceType.displayName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }
        }
    }

    private var amountSection: some View {
        Text("\(defaultCurrency) \(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)))")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
    }
}

struct SubCategoryComparisonIndicator: View {
    let amount: Double
    let currency: String
    let label: String
    let isDarkTheme: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text(formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(amountColor)
        }
    }

    private var formattedAmount: String {
        if amount == 0.0 {
            return "±0"
        } else {
            let sign = amount > 0 ? "+" : ""
            return "\(sign)\(currency) \(NumberFormatter.formatAmount(abs(amount)))"
        }
    }

    private var amountColor: Color {
        switch amount {
        case let x where x > 0:
            return .red
        case let x where x < 0:
            return .green
        default:
            return ThemeColors.getTextColor(isDarkTheme: isDarkTheme)
        }
    }
}

// MARK: - Helper Functions
extension SubCategoryDetailBottomSheet {
    private func calculateSubCategoryComparison(
        viewModel: ExpenseViewModel,
        selectedMonth: Date,
        subCategoryId: String,
        filterType: ExpenseFilterType
    ) -> CategoryComparison {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: selectedMonth)
        let currentYear = calendar.component(.year, from: selectedMonth)

        // Get previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        let prevMonth = calendar.component(.month, from: previousMonth)
        let prevYear = calendar.component(.year, from: previousMonth)

        // Filter expenses for current month
        let currentMonthExpenses = viewModel.expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseYear == currentYear &&
                   expenseMonth == currentMonth &&
                   expense.subCategoryId == subCategoryId &&
                   (filterType == .all ||
                    (filterType == .recurring && expense.recurrenceType != .NONE) ||
                    (filterType == .oneTime && expense.recurrenceType == .NONE))
        }

        // Filter expenses for previous month
        let previousMonthExpenses = viewModel.expenses.filter { expense in
            let expenseMonth = calendar.component(.month, from: expense.date)
            let expenseYear = calendar.component(.year, from: expense.date)
            return expenseYear == prevYear &&
                   expenseMonth == prevMonth &&
                   expense.subCategoryId == subCategoryId &&
                   (filterType == .all ||
                    (filterType == .recurring && expense.recurrenceType != .NONE) ||
                    (filterType == .oneTime && expense.recurrenceType == .NONE))
        }

        let currentTotal = currentMonthExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        let previousTotal = previousMonthExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }

        // Calculate 6-month average
        var averageTotal = 0.0
        var monthCount = 0

        for monthOffset in 1...6 {
            if let targetMonth = calendar.date(byAdding: .month, value: -monthOffset, to: selectedMonth) {
                let targetMonthNum = calendar.component(.month, from: targetMonth)
                let targetYear = calendar.component(.year, from: targetMonth)

                let monthExpenses = viewModel.expenses.filter { expense in
                    let expenseMonth = calendar.component(.month, from: expense.date)
                    let expenseYear = calendar.component(.year, from: expense.date)
                    return expenseYear == targetYear &&
                           expenseMonth == targetMonthNum &&
                           expense.subCategoryId == subCategoryId &&
                           (filterType == .all ||
                            (filterType == .recurring && expense.recurrenceType != .NONE) ||
                            (filterType == .oneTime && expense.recurrenceType == .NONE))
                }

                averageTotal += monthExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
                monthCount += 1
            }
        }

        let avgMonthly = monthCount > 0 ? averageTotal / Double(monthCount) : 0.0

        let vsLastMonth = currentTotal - previousTotal
        let vsAverage = currentTotal - avgMonthly

        return CategoryComparison(vsLastMonth: vsLastMonth, vsAverage: vsAverage)
    }
}

// MARK: - Preview
struct SubCategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]
        let sampleSubCategory = SubCategory.getDefaultSubCategories()[0]
        let sampleExpenses = [
            Expense(
                amount: 150.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: sampleSubCategory.id,
                description: "Restaurant expense",
                date: Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            ),
            Expense(
                amount: 75.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: sampleSubCategory.id,
                description: "Coffee shop",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            )
        ]

        let sampleSubCategoryData = SubCategoryAnalysisData(
            subCategory: sampleSubCategory,
            parentCategory: sampleCategory,
            totalAmount: 225.0,
            expenseCount: 2,
            percentage: 0.45,
            expenses: sampleExpenses
        )

        let sampleViewModel = ExpenseViewModel()

        SubCategoryDetailBottomSheet(
            subCategoryData: sampleSubCategoryData,
            defaultCurrency: "₺",
            isDarkTheme: true,
            viewModel: sampleViewModel,
            selectedMonth: Date()
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}