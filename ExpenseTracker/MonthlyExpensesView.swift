//
//  MonthlyExpensesView.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import SwiftUI

struct MonthlyExpensesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var expenseViewModel: ExpenseViewModel = ExpenseViewModel()

    let expenses: [Expense]
    let date: Date

    @State private var grouping: ExpenseGrouping = .category
    @State private var sortOrder: ExpenseSortOrder = .dateDescending
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedExpense: Expense? = nil
    @State private var showingExpenseDetail = false

    private var filteredAndGroupedExpenses: [ExpenseGroup] {
        let filtered = expenses.filter { expense in
            searchText.isEmpty ||
            expense.description.localizedCaseInsensitiveContains(searchText) ||
            expense.notes.localizedCaseInsensitiveContains(searchText)
        }

        let sorted = sortExpenses(filtered)
        return groupExpenses(sorted)
    }

    private var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d, yyyy")
        return formatter
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView

                if expenses.isEmpty {
                    emptyStateView
                } else {
                    expenseListView
                }
            }
            .background(ThemeColors.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .searchable(text: $searchText, prompt: L("search_expenses"))
            .sheet(isPresented: $showingFilters) {
                filtersView
            }
            .sheet(isPresented: $showingExpenseDetail) {
                if let selectedExpense = selectedExpense {
                    ExpenseDetailView(expense: selectedExpense)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("expenses"))
                    .font(AppTypography.titleMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Spacer()

                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(AppTypography.bodyLarge)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateFormatter.string(from: date))
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                    Text(L("total_amount"))
                        .font(AppTypography.labelMedium)
                        .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(expenses.count) \(L("expenses"))")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Text(formatCurrency(totalAmount))
                        .font(AppTypography.expenseAmountLarge)
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
            .padding()
            .background(ThemeColors.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)

            controlsView
        }
        .padding()
    }

    private var controlsView: some View {
        HStack {
            Menu {
                Button(L("group_by_category")) {
                    grouping = .category
                }
                Button(L("group_by_date")) {
                    grouping = .date
                }
                Button(L("group_by_amount")) {
                    grouping = .amount
                }
                Button(L("no_grouping")) {
                    grouping = .none
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.3.group")
                        .font(AppTypography.labelMedium)

                    Text(grouping.displayName)
                        .font(AppTypography.labelMedium)

                    Image(systemName: "chevron.down")
                        .font(AppTypography.labelSmall)
                }
                .foregroundColor(AppColors.primaryOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.primaryOrange.opacity(0.1))
                )
            }

            Spacer()

            Menu {
                Button(L("date_newest_first")) {
                    sortOrder = .dateDescending
                }
                Button(L("date_oldest_first")) {
                    sortOrder = .dateAscending
                }
                Button(L("amount_highest_first")) {
                    sortOrder = .amountDescending
                }
                Button(L("amount_lowest_first")) {
                    sortOrder = .amountAscending
                }
                Button(L("alphabetical")) {
                    sortOrder = .alphabetical
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(AppTypography.labelMedium)

                    Text(sortOrder.displayName)
                        .font(AppTypography.labelMedium)

                    Image(systemName: "chevron.down")
                        .font(AppTypography.labelSmall)
                }
                .foregroundColor(AppColors.primaryRed)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.primaryRed.opacity(0.1))
                )
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

            VStack(spacing: 8) {
                Text(L("no_expenses_found"))
                    .font(AppTypography.titleSmall)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))

                Text(searchText.isEmpty ? L("no_expenses_this_date") : L("no_expenses_match_search"))
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            if !searchText.isEmpty {
                Button(L("clear_search")) {
                    searchText = ""
                }
                .font(AppTypography.buttonText)
                .foregroundColor(AppColors.primaryOrange)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.primaryOrange.opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var expenseListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAndGroupedExpenses, id: \.id) { group in
                    expenseGroupView(group)
                }
            }
            .padding()
        }
    }

    private func expenseGroupView(_ group: ExpenseGroup) -> some View {
        VStack(spacing: 8) {
            if !group.title.isEmpty {
                HStack {
                    Text(group.title)
                        .font(AppTypography.cardTitle)
                        .foregroundColor(ThemeColors.textColor(for: colorScheme))

                    Spacer()

                    Text(formatCurrency(group.totalAmount))
                        .font(AppTypography.expenseAmount)
                        .foregroundColor(AppColors.primaryOrange)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            ForEach(group.expenses, id: \.id) { expense in
                ExpenseRowView(
                    expense: expense,
                    colorScheme: colorScheme,
                    showCategory: grouping != .category,
                    showDate: grouping != .date
                )
                .onTapGesture {
                    selectedExpense = expense
                    showingExpenseDetail = true
                }
            }
        }
        .background(ThemeColors.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var filtersView: some View {
        NavigationView {
            VStack {
                // Filter options would go here
                Text(L("filters_coming_soon"))
                    .font(AppTypography.bodyLarge)
                    .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))

                Spacer()
            }
            .padding()
            .navigationTitle(L("filters"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel")) {
                        showingFilters = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L("apply")) {
                        showingFilters = false
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func sortExpenses(_ expenses: [Expense]) -> [Expense] {
        switch sortOrder {
        case .dateDescending:
            return expenses.sorted { $0.date > $1.date }
        case .dateAscending:
            return expenses.sorted { $0.date < $1.date }
        case .amountDescending:
            return expenses.sorted { $0.amount > $1.amount }
        case .amountAscending:
            return expenses.sorted { $0.amount < $1.amount }
        case .alphabetical:
            return expenses.sorted { $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending }
        }
    }

    private func groupExpenses(_ expenses: [Expense]) -> [ExpenseGroup] {
        switch grouping {
        case .none:
            return [ExpenseGroup(
                id: "all",
                title: "",
                expenses: expenses,
                totalAmount: expenses.reduce(0) { $0 + $1.amount }
            )]

        case .category:
            let grouped = Dictionary(grouping: expenses) { $0.categoryId }
            return grouped.map { categoryId, categoryExpenses in
                ExpenseGroup(
                    id: categoryId,
                    title: getCategoryName(categoryId),
                    expenses: categoryExpenses,
                    totalAmount: categoryExpenses.reduce(0) { $0 + $1.amount }
                )
            }.sorted { $0.totalAmount > $1.totalAmount }

        case .date:
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")

            let grouped = Dictionary(grouping: expenses) { expense in
                Calendar.current.startOfDay(for: expense.date)
            }

            return grouped.map { date, dayExpenses in
                ExpenseGroup(
                    id: formatter.string(from: date),
                    title: formatter.string(from: date),
                    expenses: dayExpenses,
                    totalAmount: dayExpenses.reduce(0) { $0 + $1.amount }
                )
            }.sorted { $0.id > $1.id }

        case .amount:
            let grouped = Dictionary(grouping: expenses) { expense in
                if expense.amount < 50 {
                    return "under_50"
                } else if expense.amount < 100 {
                    return "50_to_100"
                } else if expense.amount < 500 {
                    return "100_to_500"
                } else {
                    return "over_500"
                }
            }

            let ranges = [
                ("over_500", L("over_500")),
                ("100_to_500", L("100_to_500")),
                ("50_to_100", L("50_to_100")),
                ("under_50", L("under_50"))
            ]

            return ranges.compactMap { key, title in
                guard let rangeExpenses = grouped[key], !rangeExpenses.isEmpty else { return nil }
                return ExpenseGroup(
                    id: key,
                    title: title,
                    expenses: rangeExpenses,
                    totalAmount: rangeExpenses.reduce(0) { $0 + $1.amount }
                )
            }
        }
    }

    private func getCategoryName(_ categoryId: String) -> String {
        return expenseViewModel.availableCategories.first { $0.id == categoryId }?.name ?? L("unknown_category")
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

struct ExpenseGroup {
    let id: String
    let title: String
    let expenses: [Expense]
    let totalAmount: Double
}

enum ExpenseGrouping: String, CaseIterable {
    case none = "none"
    case category = "category"
    case date = "date"
    case amount = "amount"

    var displayName: String {
        switch self {
        case .none:
            return L("no_grouping")
        case .category:
            return L("by_category")
        case .date:
            return L("by_date")
        case .amount:
            return L("by_amount")
        }
    }
}

enum ExpenseSortOrder: String, CaseIterable {
    case dateDescending = "dateDesc"
    case dateAscending = "dateAsc"
    case amountDescending = "amountDesc"
    case amountAscending = "amountAsc"
    case alphabetical = "alphabetical"

    var displayName: String {
        switch self {
        case .dateDescending:
            return L("date_newest_first")
        case .dateAscending:
            return L("date_oldest_first")
        case .amountDescending:
            return L("amount_highest_first")
        case .amountAscending:
            return L("amount_lowest_first")
        case .alphabetical:
            return L("alphabetical")
        }
    }
}

// MARK: - ExpenseRowView

struct ExpenseRowView: View {
    let expense: Expense
    let colorScheme: ColorScheme
    let showCategory: Bool
    let showDate: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            Circle()
                .fill(getCategoryColor())
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(ThemeColors.textColor(for: colorScheme))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if showDate {
                        Text(formatDate(expense.date))
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }

                    if showCategory {
                        Text("• \(getCategoryName())")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }

                    if expense.hasNotes {
                        Image(systemName: "note.text")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }

                    if expense.hasReceipt {
                        Image(systemName: "paperclip")
                            .font(AppTypography.labelSmall)
                            .foregroundColor(ThemeColors.textGrayColor(for: colorScheme))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func getCategoryColor() -> Color {
        AppColors.primaryOrange // This would come from category data
    }

    private func getCategoryName() -> String {
        L("unknown_category") // This would come from category data
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("M/d")
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // This would come from settings
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}

// MARK: - ExpenseDetailView

struct ExpenseDetailView: View {
    let expense: Expense

    var body: some View {
        NavigationView {
            VStack {
                Text("Expense details for: \(expense.description)")
                    .padding()
                Spacer()
            }
            .navigationTitle(L("expense_details"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MonthlyExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let mockExpenses = [
            Expense(amount: 50, categoryId: "food", subCategoryId: "restaurants", description: "Lunch at cafe"),
            Expense(amount: 120, categoryId: "transport", subCategoryId: "fuel", description: "Gas station"),
            Expense(amount: 75, categoryId: "shopping", subCategoryId: "clothes", description: "New shirt")
        ]

        MonthlyExpensesView(
            expenses: mockExpenses,
            date: Date()
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif