//
//  AnalysisView.swift
//  ExpenseTracker
//
//  Created by migration from Android AnalysisScreen.kt
//

import SwiftUI

// MARK: - Data Types (CategoryComparison imported from CategoryDetailBottomSheet)

struct AnalysisView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    let isDarkTheme: Bool

    @State private var selectedMonth = Calendar.current.dateComponents([.year, .month], from: Date())
    @State private var selectedCategoryForDetail: CategoryAnalysisData?
    @State private var selectedSubCategoryForDetail: SubCategoryAnalysisData?
    @State private var sortOption: SortOption = .dateDesc
    @State private var showSortMenu = false
    @State private var selectedSegment: Int?
    @State private var selectedMonthlyExpenseType: ExpenseFilterType = .all
    @State private var showDateRangePicker = false
    @State private var selectedDateRange: DateRange?

    // Animation states for popup (matching Kotlin implementation)
    @State private var line1Progress: Double = 0
    @State private var line2Progress: Double = 0
    @State private var popupScale: Double = 0

    private var selectedMonthDate: Date {
        Calendar.current.date(from: selectedMonth) ?? Date()
    }

    private var monthlyExpenses: [Expense] {
        let calendar = Calendar.current

        if let dateRange = selectedDateRange {
            return viewModel.expenses.filter { expense in
                expense.date >= dateRange.startDate && expense.date <= dateRange.endDate
            }
        } else {
            let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonthDate)?.start ?? selectedMonthDate
            let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonthDate)?.end ?? selectedMonthDate

            return viewModel.expenses.filter { expense in
                expense.date >= startOfMonth && expense.date <= endOfMonth
            }
        }
    }

    private var categoryAnalysisData: [CategoryAnalysisData] {
        getFilteredCategoryAnalysisData(
            monthlyExpenses: monthlyExpenses,
            categories: viewModel.categories,
            defaultCurrency: viewModel.defaultCurrency,
            filterType: selectedMonthlyExpenseType
        )
    }

    private var subCategoryAnalysisData: [SubCategoryAnalysisData] {
        getFilteredSubCategoryAnalysisData(
            monthlyExpenses: monthlyExpenses,
            categories: viewModel.categories,
            subCategories: viewModel.subCategories,
            defaultCurrency: viewModel.defaultCurrency,
            filterType: selectedMonthlyExpenseType
        )
    }

    private var totalMonthlyAmount: Double {
        categoryAnalysisData.reduce(0) { $0 + $1.totalAmount }
    }

    private var recurringExpenseTotal: Double {
        let calendar = Calendar.current
        let threeMonthsFromNow = calendar.date(byAdding: .month, value: 3, to: selectedMonthDate) ?? selectedMonthDate
        let oneMonthBefore = calendar.date(byAdding: .month, value: -1, to: selectedMonthDate) ?? selectedMonthDate

        return viewModel.expenses.filter { expense in
            expense.recurrenceType != .NONE &&
            (expense.endDate == nil || expense.endDate! > threeMonthsFromNow) &&
            expense.date < selectedMonthDate &&
            expense.date >= oneMonthBefore
        }.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
    }

    var body: some View {
        ZStack {
            ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Month/Year Selector
                monthYearSelector

                // Expense Filter Type Selection
                expenseFilterTypeSelector

                if !categoryAnalysisData.isEmpty {
                    // Box with gesture handling for popup dismissal (matching Kotlin)
                    ZStack {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Total and Comparison Indicators
                                totalComparisonSection

                                // Monthly Analysis Pie Chart
                                MonthlyAnalysisPieChart(
                                    categoryData: categoryAnalysisData,
                                    isDarkTheme: isDarkTheme,
                                    onSegmentSelected: { segment in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedSegment = segment
                                        }
                                    }
                                )

                                // Monthly Line Chart
                                MonthlyLineChart(
                                    data: getMonthlyChartData(),
                                    currency: viewModel.defaultCurrency,
                                    isDarkTheme: isDarkTheme
                                )

                                // Recurring Expense Card
                                if recurringExpenseTotal > 0 {
                                    recurringExpenseCard
                                }

                                // Category Summary Section
                                CategorySummarySection(
                                    categoryData: categoryAnalysisData,
                                    subCategoryData: subCategoryAnalysisData,
                                    totalAmount: totalMonthlyAmount,
                                    defaultCurrency: viewModel.defaultCurrency,
                                    isDarkTheme: isDarkTheme,
                                    onCategoryClick: { categoryData in
                                        selectedCategoryForDetail = categoryData
                                    },
                                    onSubCategoryClick: { subCategoryData in
                                        selectedSubCategoryForDetail = subCategoryData
                                    }
                                )
                            }
                            .padding(.horizontal, 16)
                        }

                        // Overlay popup that appears above everything (matching Kotlin)
                        if let selectedSegment = selectedSegment,
                           selectedSegment < categoryAnalysisData.count {
                            let selectedData = categoryAnalysisData[selectedSegment]

                            VStack {
                                Spacer().frame(height: 360) // Position relative to pie chart

                                CategoryPopupCard(
                                    selectedCategory: selectedData,
                                    defaultCurrency: viewModel.defaultCurrency,
                                    comparisonData: CategoryComparisonData(
                                        vsLastMonth: calculateCategoryComparison(selectedData.category.id).vsLastMonth,
                                        vsAverage: calculateCategoryComparison(selectedData.category.id).vsAverage
                                    ),
                                    popupScale: popupScale,
                                    onCategoryClick: { categoryData in
                                        selectedCategoryForDetail = categoryData
                                    },
                                    isDarkTheme: isDarkTheme
                                )
                                .scaleEffect(popupScale)
                                .opacity(popupScale)

                                Spacer()
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        // Dismiss popup when tapping outside (matching Kotlin logic)
                        if selectedSegment != nil {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSegment = nil
                            }
                        }
                    }
                } else {
                    emptyStateView
                }
            }
        }
        .onChange(of: selectedSegment) { newValue in
            // Animate popup appearance/disappearance (matching Kotlin)
            if newValue != nil {
                withAnimation(.easeOut(duration: 0.4)) {
                    line1Progress = 1.0
                }
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    line2Progress = 1.0
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    popupScale = 1.0
                }
            } else {
                withAnimation(.easeIn(duration: 0.15)) {
                    popupScale = 0.0
                    line2Progress = 0.0
                    line1Progress = 0.0
                }
            }
        }
        .sheet(item: $selectedCategoryForDetail) { categoryData in
            CategoryDetailBottomSheet(
                categoryData: categoryData,
                subCategories: viewModel.subCategories,
                defaultCurrency: viewModel.defaultCurrency,
                isDarkTheme: isDarkTheme,
                viewModel: viewModel,
                selectedMonth: selectedMonthDate,
                selectedFilterType: selectedMonthlyExpenseType,
                onSortOptionChanged: { newOption in
                    sortOption = newOption
                }
            )
            .environmentObject(viewModel)
        }
        .sheet(item: $selectedSubCategoryForDetail) { subCategoryData in
            SubCategoryDetailBottomSheet(
                subCategoryData: subCategoryData,
                defaultCurrency: viewModel.defaultCurrency,
                isDarkTheme: isDarkTheme,
                viewModel: viewModel,
                selectedMonth: selectedMonthDate,
                selectedFilterType: selectedMonthlyExpenseType
            )
            .environmentObject(viewModel)
        }
        .sheet(isPresented: $showDateRangePicker) {
            dateRangePickerSheet
        }
    }
}

// MARK: - View Components
extension AnalysisView {
    private var monthYearSelector: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            Button(action: { showDateRangePicker = true }) {
                VStack(spacing: 4) {
                    Text(monthYearString)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    if selectedDateRange != nil {
                        Text(dateRangeString)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
                .cornerRadius(12)
            }

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
        }
        .padding(.horizontal, 16)
    }

    private var expenseFilterTypeSelector: some View {
        HStack {
            ForEach(ExpenseFilterType.allCases, id: \.rawValue) { filterType in
                HStack(spacing: 4) {
                    Button(action: {
                        selectedMonthlyExpenseType = filterType
                    }) {
                        Image(systemName: selectedMonthlyExpenseType == filterType ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedMonthlyExpenseType == filterType ? AppColors.primaryOrange : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    }

                    Text(filterType.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(selectedMonthlyExpenseType == filterType ? ThemeColors.getTextColor(isDarkTheme: isDarkTheme) : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
                .onTapGesture {
                    selectedMonthlyExpenseType = filterType
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var totalComparisonSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("current_period_total".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Spacer()

                Text("\(viewModel.defaultCurrency) \(NumberFormatter.formatAmount(totalMonthlyAmount))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.primaryOrange)
            }

            let totalComparison = calculateTotalComparison()

            TotalComparisonIndicator(
                amount: totalComparison.vsLastMonth,
                currency: viewModel.defaultCurrency,
                label: "vs_previous_month".localized,
                isDarkTheme: isDarkTheme
            )

            TotalComparisonIndicator(
                amount: totalComparison.vsAverage,
                currency: viewModel.defaultCurrency,
                label: "vs_6_month_average".localized,
                isDarkTheme: isDarkTheme
            )
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
    }

    private var recurringExpenseCard: some View {
        HStack {
            HStack {
                Image(systemName: "repeat")
                    .foregroundColor(AppColors.primaryOrange)
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 4) {
                    Text("fixed_expenses".localized)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Text("recurring_expenses_description".localized)
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }

            Spacer()

            Text("\(viewModel.defaultCurrency) \(NumberFormatter.formatAmount(recurringExpenseTotal))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.primaryOrange)
        }
        .padding(16)
        .background(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("📊")
                .font(.system(size: 64))

            Text("no_expenses_this_period".localized)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Text("analysis_will_appear".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Sheet Views

    private var dateRangePickerSheet: some View {
        DateRangePicker(
            selectedRange: $selectedDateRange,
            onRangeSelected: { newRange in
                selectedDateRange = newRange
                showDateRangePicker = false
            },
            isDarkTheme: isDarkTheme
        )
    }
}

// MARK: - Helper Methods
extension AnalysisView {
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: selectedMonthDate)
    }

    private var dateRangeString: String {
        guard let dateRange = selectedDateRange else {
            return "pick_date_range".localized
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"

        return "\(formatter.string(from: dateRange.startDate)) - \(formatter.string(from: dateRange.endDate))"
    }

    private func previousMonth() {
        let calendar = Calendar.current
        let currentDate = calendar.date(from: selectedMonth) ?? Date()
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            selectedMonth = calendar.dateComponents([.year, .month], from: newDate)
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        let currentDate = calendar.date(from: selectedMonth) ?? Date()
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            selectedMonth = calendar.dateComponents([.year, .month], from: newDate)
        }
    }

    private func getMonthlyChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let filteredExpenses = getFilteredExpenses(monthlyExpenses, filterType: selectedMonthlyExpenseType)

        let dailyExpenses = Dictionary(grouping: filteredExpenses) { expense in
            calendar.component(.day, from: expense.date)
        }.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        }

        if let dateRange = selectedDateRange {
            // Generate chart data for selected date range
            var result: [ChartDataPoint] = []
            var currentDate = dateRange.startDate

            while currentDate <= dateRange.endDate {
                let day = calendar.component(.day, from: currentDate)
                let amount = dailyExpenses[day] ?? 0.0
                result.append(ChartDataPoint(day: day, amount: amount))

                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }

            return result
        } else {
            // Generate chart data for entire month
            let range = calendar.range(of: .day, in: .month, for: selectedMonthDate) ?? 1..<32

            return range.map { day in
                ChartDataPoint(day: day, amount: dailyExpenses[day] ?? 0.0)
            }
        }
    }

    private func calculateTotalComparison() -> CategoryComparison {
        let calendar = Calendar.current
        let currentDate = calendar.date(from: selectedMonth) ?? Date()

        // Current month total
        let currentMonthExpenses = getFilteredExpenses(monthlyExpenses, filterType: selectedMonthlyExpenseType)
        let currentAmount = currentMonthExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }

        // Previous month total
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return CategoryComparison(vsLastMonth: 0, vsAverage: 0)
        }

        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonthDate)?.start ?? previousMonthDate
        let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonthDate)?.end ?? previousMonthDate

        let previousMonthExpenses = viewModel.expenses.filter { expense in
            expense.date >= previousMonthStart && expense.date <= previousMonthEnd
        }
        let previousAmount = getFilteredExpenses(previousMonthExpenses, filterType: selectedMonthlyExpenseType)
            .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }

        // 6-month average
        var totalAmount = currentAmount
        for i in 1..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: currentDate) else { continue }
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate

            let monthExpenses = viewModel.expenses.filter { expense in
                expense.date >= monthStart && expense.date <= monthEnd
            }
            totalAmount += getFilteredExpenses(monthExpenses, filterType: selectedMonthlyExpenseType)
                .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        }

        let avgAmount = totalAmount / 6.0

        return CategoryComparison(
            vsLastMonth: currentAmount - previousAmount,
            vsAverage: currentAmount - avgAmount
        )
    }

    private func calculateCategoryComparison(_ categoryId: String) -> CategoryComparison {
        let calendar = Calendar.current
        let currentDate = calendar.date(from: selectedMonth) ?? Date()

        // Current month amount for category
        let currentMonthExpenses = getFilteredExpenses(monthlyExpenses, filterType: selectedMonthlyExpenseType)
            .filter { $0.categoryId == categoryId }
        let currentAmount = currentMonthExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }

        // Previous month amount for category
        guard let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) else {
            return CategoryComparison(vsLastMonth: 0, vsAverage: 0)
        }

        let previousMonthStart = calendar.dateInterval(of: .month, for: previousMonthDate)?.start ?? previousMonthDate
        let previousMonthEnd = calendar.dateInterval(of: .month, for: previousMonthDate)?.end ?? previousMonthDate

        let previousMonthExpenses = viewModel.expenses.filter { expense in
            expense.date >= previousMonthStart && expense.date <= previousMonthEnd && expense.categoryId == categoryId
        }
        let previousAmount = getFilteredExpenses(previousMonthExpenses, filterType: selectedMonthlyExpenseType)
            .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }

        // 6-month average for category
        var totalAmount = currentAmount
        for i in 1..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: currentDate) else { continue }
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate

            let monthExpenses = viewModel.expenses.filter { expense in
                expense.date >= monthStart && expense.date <= monthEnd && expense.categoryId == categoryId
            }
            totalAmount += getFilteredExpenses(monthExpenses, filterType: selectedMonthlyExpenseType)
                .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        }

        let avgAmount = totalAmount / 6.0

        return CategoryComparison(
            vsLastMonth: currentAmount - previousAmount,
            vsAverage: currentAmount - avgAmount
        )
    }
}

// MARK: - Helper Functions
private func getFilteredExpenses(_ expenses: [Expense], filterType: ExpenseFilterType) -> [Expense] {
    switch filterType {
    case .all:
        return expenses
    case .recurring:
        return expenses.filter { $0.recurrenceType != .NONE }
    case .oneTime:
        return expenses.filter { $0.recurrenceType == .NONE }
    }
}

private func getFilteredCategoryAnalysisData(
    monthlyExpenses: [Expense],
    categories: [Category],
    defaultCurrency: String,
    filterType: ExpenseFilterType
) -> [CategoryAnalysisData] {
    guard !monthlyExpenses.isEmpty else { return [] }

    let filteredExpenses = getFilteredExpenses(monthlyExpenses, filterType: filterType)
    let totalAmount = filteredExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

    let categoryTotals = Dictionary(grouping: filteredExpenses) { $0.categoryId }
        .compactMap { (categoryId, categoryExpenses) -> CategoryAnalysisData? in
            guard let category = categories.first(where: { $0.id == categoryId }) else { return nil }

            let amount = categoryExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

            return CategoryAnalysisData(
                category: category,
                totalAmount: amount,
                expenseCount: categoryExpenses.count,
                percentage: totalAmount > 0 ? amount / totalAmount : 0.0,
                expenses: categoryExpenses.sorted { $0.date > $1.date }
            )
        }
        .sorted { $0.totalAmount > $1.totalAmount }

    return categoryTotals
}

private func getFilteredSubCategoryAnalysisData(
    monthlyExpenses: [Expense],
    categories: [Category],
    subCategories: [SubCategory],
    defaultCurrency: String,
    filterType: ExpenseFilterType
) -> [SubCategoryAnalysisData] {
    guard !monthlyExpenses.isEmpty else { return [] }

    let filteredExpenses = getFilteredExpenses(monthlyExpenses, filterType: filterType)
    let totalAmount = filteredExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

    let subCategoryTotals = Dictionary(grouping: filteredExpenses) { $0.subCategoryId }
        .compactMap { (subCategoryId, subCategoryExpenses) -> SubCategoryAnalysisData? in
            guard let subCategory = subCategories.first(where: { $0.id == subCategoryId }),
                  let parentCategory = categories.first(where: { $0.id == subCategory.categoryId }) else { return nil }

            let amount = subCategoryExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

            return SubCategoryAnalysisData(
                subCategory: subCategory,
                parentCategory: parentCategory,
                totalAmount: amount,
                expenseCount: subCategoryExpenses.count,
                percentage: totalAmount > 0 ? amount / totalAmount : 0.0,
                expenses: subCategoryExpenses
            )
        }
        .sorted { $0.totalAmount > $1.totalAmount }

    return subCategoryTotals
}

// MARK: - Comparison Indicator
struct TotalComparisonIndicator: View {
    let amount: Double
    let currency: String
    let label: String
    let isDarkTheme: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fontWeight(.bold)

            Spacer()

            Text(comparisonText)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(comparisonColor)
        }
    }

    private var comparisonText: String {
        if amount == 0.0 {
            return "±0"
        } else {
            let prefix = amount > 0 ? "+" : ""
            return "\(prefix)\(currency) \(NumberFormatter.formatAmount(abs(amount)))"
        }
    }

    private var comparisonColor: Color {
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

// MARK: - Preview
struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()

        AnalysisView(isDarkTheme: true)
            .environmentObject(viewModel)
    }
}
