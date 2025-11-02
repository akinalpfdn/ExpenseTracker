//
//  CategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by migration from Android CategoryDetailBottomSheet.kt
//

import SwiftUI

enum SortOption: String, CaseIterable {
    case amountDesc = "AMOUNT_DESC"
    case amountAsc = "AMOUNT_ASC"
    case dateDesc = "DATE_DESC"
    case dateAsc = "DATE_ASC"
    case nameAsc = "NAME_ASC"
    case nameDesc = "NAME_DESC"

    var displayName: String {
        switch self {
        case .amountDesc:
            return "sort_amount_desc".localized
        case .amountAsc:
            return "sort_amount_asc".localized
        case .dateDesc:
            return "sort_date_desc".localized
        case .dateAsc:
            return "sort_date_asc".localized
        case .nameAsc:
            return "sort_name_asc".localized
        case .nameDesc:
            return "sort_name_desc".localized
        }
    }
}

struct CategoryComparison {
    let vsLastMonth: Double
    let vsAverage: Double
}

struct CategoryDetailBottomSheet: View {
    let categoryData: CategoryAnalysisData
    let subCategories: [SubCategory]
    let defaultCurrency: String
    let isDarkTheme: Bool
    let viewModel: ExpenseViewModel
    let selectedMonth: Date
    let selectedFilterType: ExpenseFilterType
    let onSortOptionChanged: (SortOption) -> Void

    @State private var sortOption: SortOption = .dateDesc
    @State private var showSortMenu = false

    init(
        categoryData: CategoryAnalysisData,
        subCategories: [SubCategory] = [],
        defaultCurrency: String = "₺",
        isDarkTheme: Bool = true,
        viewModel: ExpenseViewModel,
        selectedMonth: Date,
        selectedFilterType: ExpenseFilterType = .all,
        onSortOptionChanged: @escaping (SortOption) -> Void = { _ in }
    ) {
        self.categoryData = categoryData
        self.subCategories = subCategories
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.viewModel = viewModel
        self.selectedMonth = selectedMonth
        self.selectedFilterType = selectedFilterType
        self.onSortOptionChanged = onSortOptionChanged
    }

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            sortSection
            expensesList
        }
        .padding(20)
        .background(categoryData.category.getColor().opacity(0.1))
    }
}

// MARK: - Computed Properties
extension CategoryDetailBottomSheet {
    private var sortedExpenses: [Expense] {
        switch sortOption {
        case .amountDesc:
            return categoryData.expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .amountAsc:
            return categoryData.expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .dateDesc:
            return categoryData.expenses.sorted { $0.date > $1.date }
        case .dateAsc:
            return categoryData.expenses.sorted { $0.date < $1.date }
        case .nameAsc:
            return categoryData.expenses.sorted { $0.description.lowercased() < $1.description.lowercased() }
        case .nameDesc:
            return categoryData.expenses.sorted { $0.description.lowercased() > $1.description.lowercased() }
        }
    }

    private var comparison: CategoryComparison {
        calculateCategoryComparison(
            viewModel: viewModel,
            selectedMonth: selectedMonth,
            categoryId: categoryData.category.id,
            filterType: selectedFilterType
        )
    }
}

// MARK: - View Components
extension CategoryDetailBottomSheet {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            categoryHeaderRow
            categoryMetrics
            comparisonIndicators
        }
    }

    private var categoryHeaderRow: some View {
        HStack(alignment: .center, spacing: 12) {
            categoryIcon

            VStack(alignment: .leading, spacing: 6) {
                Text(categoryData.category.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                categoryAmountRow
            }

            Spacer()
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(categoryData.category.getColor().opacity(0.2))
                .frame(width: 48, height: 48)

            Image(systemName: categoryData.category.getIcon())
                .foregroundColor(categoryData.category.getColor())
                .font(.system(size: 24))
        }
    }

    private var categoryAmountRow: some View {
        HStack(spacing: 4) {
            Text("\(defaultCurrency) \(NumberFormatter.formatAmount(categoryData.totalAmount))")
                .font(.system(size: 18))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text("  •  \(categoryData.expenseCount) \("expense_lowercase".localized) • \(String(format: "%.1f", categoryData.percentage * 100))%")
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    private var categoryMetrics: some View {
        EmptyView()
    }

    private var comparisonIndicators: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailComparisonIndicator(
                amount: comparison.vsLastMonth,
                currency: defaultCurrency,
                label: "vs_previous_month".localized,
                isDarkTheme: isDarkTheme
            )

            DetailComparisonIndicator(
                amount: comparison.vsAverage,
                currency: defaultCurrency,
                label: "vs_6_month_average".localized,
                isDarkTheme: isDarkTheme
            )
        }
    }

    private var sortSection: some View {
        VStack(spacing: 16) {
            Rectangle()
                .fill(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.2))
                .frame(height: 1)

            sortButton
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    sortOption = option
                    onSortOptionChanged(option)
                }) {
                    Text(option.displayName)
                }
            }
        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16))

                Spacer().frame(width: 8)

                Text(sortOption.displayName)
                    .font(.system(size: 14))

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
            }
            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
            )
        }
    }

    private var expensesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(sortedExpenses, id: \.id) { expense in
                    ExpenseDetailCard(
                        expense: expense,
                        subCategory: subCategories.first { $0.id == expense.subCategoryId },
                        defaultCurrency: defaultCurrency,
                        isDarkTheme: isDarkTheme
                    )
                }
            }
            .padding(.top, 16)
        }
    }
}

struct ExpenseDetailCard: View {
    let expense: Expense
    let subCategory: SubCategory?
    let defaultCurrency: String
    let isDarkTheme: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader

            if !expense.description.isEmpty {
                Text(expense.description)
                    .font(.system(size: 15))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }

            cardFooter
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
    }
}

// MARK: - Expense Detail Card Components
extension ExpenseDetailCard {
    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subCategory?.name ?? "unknown".localized)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(defaultCurrency) \(NumberFormatter.formatAmount(expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                if let exchangeRate = expense.exchangeRate, expense.currency != defaultCurrency {
                    Text("\(expense.currency) \(NumberFormatter.formatAmount(expense.amount))")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }
        }
    }

    private var cardFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(expense.date, style: .date)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            if expense.recurrenceType != .NONE {
                Text("\("recurring_label".localized): \(expense.recurrenceType.displayName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }
        }
    }
}

struct DetailComparisonIndicator: View {
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
            let sign = amount > 0 ? "+" : amount <   0 ?"-" : ""
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
extension CategoryDetailBottomSheet {
    private func calculateCategoryComparison(
        viewModel: ExpenseViewModel,
        selectedMonth: Date,
        categoryId: String,
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
                   expense.categoryId == categoryId &&
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
                   expense.categoryId == categoryId &&
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
                           expense.categoryId == categoryId &&
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
struct CategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCategory = Category.getDefaultCategories()[0]
        let sampleExpenses = [
            Expense(
                amount: 150.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: "restaurant",
                description: "Lunch at restaurant",
                date: Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            ),
            Expense(
                amount: 75.0,
                currency: "₺",
                categoryId: sampleCategory.id,
                subCategoryId: "groceries",
                description: "Weekly groceries",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            )
        ]

        let sampleCategoryData = CategoryAnalysisData(
            category: sampleCategory,
            totalAmount: 225.0,
            expenseCount: 2,
            percentage: 0.45,
            expenses: sampleExpenses
        )

        let sampleSubCategories = SubCategory.getDefaultSubCategories()
        let sampleViewModel = ExpenseViewModel()

        CategoryDetailBottomSheet(
            categoryData: sampleCategoryData,
            subCategories: sampleSubCategories,
            defaultCurrency: "₺",
            isDarkTheme: true,
            viewModel: sampleViewModel,
            selectedMonth: Date()
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
