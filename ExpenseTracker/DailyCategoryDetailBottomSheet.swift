//
//  DailyCategoryDetailBottomSheet.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct DailyCategoryDetailBottomSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var expenseViewModel: ExpenseViewModel = ExpenseViewModel()

    let categoryId: String
    let date: Date
    let expenses: [Expense]

    @State private var showingExpensesList = false
    @State private var selectedExpense: Expense? = nil
    @State private var showingExpenseDetail = false

    private var dayExpenses: [Expense] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        return expenses.filter { expense in
            expense.categoryId == categoryId &&
            expense.date >= dayStart &&
            expense.date < dayEnd
        }
    }

    private var categoryName: String {
        expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
    }

    private var totalAmount: Double {
        dayExpenses.reduce(0) { $0 + $1.amount }
    }

    private var subcategoryBreakdown: [SubcategoryData] {
        let grouped = Dictionary(grouping: dayExpenses) { $0.subCategoryId }
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

    private var hourlyBreakdown: [HourlyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dayExpenses) { expense in
            calendar.component(.hour, from: expense.date)
        }

        return grouped.map { hour, hourExpenses in
            HourlyData(
                hour: hour,
                amount: hourExpenses.reduce(0) { $0 + $1.amount },
                expenseCount: hourExpenses.count
            )
        }.sorted { $0.hour < $1.hour }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    summarySection
                    subcategorySection
                    timelineSection
                    expensesSection
                    quickActionsSection
                }
                .padding()
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationTitle(L("daily_breakdown"))
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
                expenses: dayExpenses,
                date: date
            )
        }
        .sheet(isPresented: $showingExpenseDetail) {
            if let selectedExpense = selectedExpense {
                ExpenseDetailView(expense: selectedExpense)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(getCategoryColor())
                    .frame(width: 20, height: 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryName)
                        .font(AppTypography.titleMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text(formatDate(date))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }

                Spacer()
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

                    Text("\(dayExpenses.count)")
                        .font(AppTypography.titleSmall)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("day_summary"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                summaryCard(
                    title: L("avg_per_transaction"),
                    value: formatCurrency(dayExpenses.isEmpty ? 0 : totalAmount / Double(dayExpenses.count)),
                    icon: "chart.bar",
                    color: AppColors.successGreen
                )

                summaryCard(
                    title: L("largest_expense"),
                    value: formatCurrency(dayExpenses.map { $0.amount }.max() ?? 0),
                    icon: "arrow.up.circle",
                    color: AppColors.primaryRed
                )

                summaryCard(
                    title: L("first_expense"),
                    value: formatTime(dayExpenses.min(by: { $0.date < $1.date })?.date ?? date),
                    icon: "clock",
                    color: .blue
                )

                summaryCard(
                    title: L("last_expense"),
                    value: formatTime(dayExpenses.max(by: { $0.date < $1.date })?.date ?? date),
                    icon: "clock.fill",
                    color: AppColors.primaryOrange
                )
            }
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
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

    private var subcategorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("subcategories"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

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
                    ForEach(subcategoryBreakdown, id: \.id) { subcategory in
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
        }
        .padding(.vertical, 4)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("hourly_breakdown"))
                .font(AppTypography.cardTitle)
                .foregroundColor(ThemeColors.textColor(for: colorScheme))

            if hourlyBreakdown.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 30))
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("no_hourly_data"))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .frame(height: 80)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(hourlyBreakdown, id: \.hour) { hourData in
                            hourlyCard(hourData)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }

    private func hourlyCard(_ hourData: HourlyData) -> some View {
        VStack(spacing: 4) {
            Text(formatHour(hourData.hour))
                .font(AppTypography.labelSmall)
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            VStack(spacing: 2) {
                Text(formatCurrency(hourData.amount))
                    .font(AppTypography.labelMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text("(\(hourData.expenseCount))")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }
        }
        .padding(8)
        .background(AppColors.primaryOrange.opacity(0.1))
        .cornerRadius(8)
        .frame(width: 80)
    }

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("all_expenses"))
                    .font(AppTypography.cardTitle)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                if dayExpenses.count > 3 {
                    Button(L("view_all")) {
                        showingExpensesList = true
                    }
                    .font(AppTypography.labelMedium)
                    .foregroundColor(AppColors.primaryOrange)
                }
            }

            if dayExpenses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("no_expenses_today"))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }
                .frame(height: 80)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(dayExpenses.prefix(3)), id: \.id) { expense in
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
        Button(action: {
            selectedExpense = expense
            showingExpenseDetail = true
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(formatTime(expense.date))
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                        Text("• \(getSubcategoryName(expense.subCategoryId))")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
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

                Image(systemName: "chevron.right")
                    .font(AppTypography.labelSmall)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                actionButton(
                    title: L("add_expense"),
                    icon: "plus.circle",
                    color: AppColors.successGreen
                ) {
                    expenseViewModel.prepareNewExpenseForm()
                    expenseViewModel.newExpenseForm.categoryId = categoryId
                    expenseViewModel.newExpenseForm.date = date
                    expenseViewModel.showingAddExpense = true
                }

                actionButton(
                    title: L("view_all"),
                    icon: "list.bullet",
                    color: AppColors.primaryOrange
                ) {
                    showingExpensesList = true
                }
            }

            HStack {
                actionButton(
                    title: L("compare_days"),
                    icon: "chart.bar.xaxis",
                    color: .blue
                ) {
                    // Handle compare days
                }

                actionButton(
                    title: L("set_daily_limit"),
                    icon: "target",
                    color: .purple
                ) {
                    // Handle set daily limit
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter.string(from: date)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("HH:00")

        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct HourlyData {
    let hour: Int
    let amount: Double
    let expenseCount: Int
}

// MARK: - Preview

#if DEBUG
struct DailyCategoryDetailBottomSheet_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 25, categoryId: "food", subCategoryId: "restaurants", description: "Morning coffee"),
            Expense(amount: 45, categoryId: "food", subCategoryId: "restaurants", description: "Lunch"),
            Expense(amount: 80, categoryId: "food", subCategoryId: "restaurants", description: "Dinner")
        ]

        DailyCategoryDetailBottomSheet(
            categoryId: "food",
            date: Date(),
            expenses: mockExpenses
        )
    }
}
#endif