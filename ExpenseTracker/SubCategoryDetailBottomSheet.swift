//
//  SubCategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI
import Charts

struct SubCategoryDetailBottomSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel = ExpenseViewModel()

    let categoryId: String
    let subCategoryId: String
    let expenses: [Expense]
    let month: Date

    @State private var selectedTimeRange: DetailTimeRange = .thisMonth
    @State private var showingExpensesList = false

    private var subCategoryExpenses: [Expense] {
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
            expense.subCategoryId == subCategoryId &&
            expense.date >= startDate &&
            expense.date < endDate
        }
    }

    private var categoryName: String {
        expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private var subCategoryName: String {
        expenseViewModel.availableSubCategories.first { $0.id == subCategoryId }?.name ?? L("unknown_subcategory")
    }

    private var totalAmount: Double {
        subCategoryExpenses.reduce(0) { $0 + $1.amount }
    }

    private var dailySpendingData: [DailySpendingData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: subCategoryExpenses) { expense in
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

    private var recentExpenses: [Expense] {
        Array(subCategoryExpenses.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    overviewSection
                    chartSection
                    recentExpensesSection
                    quickActionsSection
                }
                .padding()
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationTitle(subCategoryName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("back")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("done")) {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExpensesList) {
            MonthlyExpensesView(
                expenses: subCategoryExpenses,
                date: month
            )
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(getSubCategoryColor())
                            .frame(width: 12, height: 12)

                        Text(categoryName)
                            .font(AppTypography.labelMedium)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }

                    Text(subCategoryName)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                }

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

                    Text("\(subCategoryExpenses.count)")
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
                    value: formatCurrency(subCategoryExpenses.isEmpty ? 0 : totalAmount / Double(subCategoryExpenses.count)),
                    icon: "chart.bar",
                    color: AppColors.successGreen
                )

                overviewCard(
                    title: L("highest_expense"),
                    value: formatCurrency(subCategoryExpenses.map { $0.amount }.max() ?? 0),
                    icon: "arrow.up.circle",
                    color: AppColors.primaryRed
                )

                overviewCard(
                    title: L("lowest_expense"),
                    value: formatCurrency(subCategoryExpenses.map { $0.amount }.min() ?? 0),
                    icon: "arrow.down.circle",
                    color: AppColors.successGreen
                )

                overviewCard(
                    title: L("frequency"),
                    value: frequencyDescription,
                    icon: "clock",
                    color: .blue
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
                    LineMark(
                        x: .value(L("date"), data.date),
                        y: .value(L("amount"), data.amount)
                    )
                    .foregroundStyle(AppColors.primaryOrange)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    PointMark(
                        x: .value(L("date"), data.date),
                        y: .value(L("amount"), data.amount)
                    )
                    .foregroundStyle(AppColors.primaryOrange)
                    .symbolSize(40)
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

    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("recent_expenses"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                if subCategoryExpenses.count > 5 {
                    Button(L("view_all")) {
                        showingExpensesList = true
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.primaryOrange)
                }
            }

            if recentExpenses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("no_recent_expenses"))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .frame(height: 80)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentExpenses, id: \.id) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)

                Text(formatDate(expense.date))
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(expense.amount))
                    .font(AppTypography.expenseAmount)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                if expense.status != .confirmed {
                    Text(expense.status.displayName)
                        .font(AppTypography.labelSmall)
                        .foregroundColor(expense.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(expense.status.color.opacity(0.1))
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                actionButton(
                    title: L("view_all_expenses"),
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
                    expenseViewModel.prepareNewExpenseForm()
                    expenseViewModel.newExpenseForm.categoryId = categoryId
                    expenseViewModel.newExpenseForm.subCategoryId = subCategoryId
                    expenseViewModel.showingAddExpense = true
                }
            }

            HStack {
                actionButton(
                    title: L("compare_periods"),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    // Handle compare periods
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

    private var frequencyDescription: String {
        guard !subCategoryExpenses.isEmpty else { return L("none") }

        let totalDays = selectedTimeRange == .thisMonth || selectedTimeRange == .lastMonth ? 30 :
                       selectedTimeRange == .last30Days ? 30 :
                       selectedTimeRange == .last90Days ? 90 : 365

        let frequency = Double(subCategoryExpenses.count) / Double(totalDays) * 30 // Per month

        if frequency >= 1 {
            return L("n_times_per_month", Int(frequency))
        } else if frequency >= 0.25 {
            return L("weekly")
        } else {
            return L("occasional")
        }
    }

    // MARK: - Helper Functions

    private func getSubCategoryColor() -> Color {
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#if DEBUG
struct SubCategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 50, categoryId: "food", subCategoryId: "restaurants", description: "Lunch at cafe"),
            Expense(amount: 25, categoryId: "food", subCategoryId: "restaurants", description: "Coffee"),
            Expense(amount: 80, categoryId: "food", subCategoryId: "restaurants", description: "Dinner")
        ]

        SubCategoryDetailBottomSheet(
            categoryId: "food",
            subCategoryId: "restaurants",
            expenses: mockExpenses,
            month: Date()
        )
    }
}
#endif