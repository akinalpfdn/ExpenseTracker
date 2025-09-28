//
//  MonthlyExpensesView.swift
//  ExpenseTracker
//
//  Created by migration from Android MonthlyExpensesView.kt
//

import SwiftUI

enum ExpenseSortType: String, CaseIterable {
    case timeNewestFirst = "TIME_NEWEST_FIRST"
    case timeOldestFirst = "TIME_OLDEST_FIRST"
    case amountHighToLow = "AMOUNT_HIGH_TO_LOW"
    case amountLowToHigh = "AMOUNT_LOW_TO_HIGH"
    case descriptionAToZ = "DESCRIPTION_A_TO_Z"
    case descriptionZToA = "DESCRIPTION_Z_TO_A"
    case categoryAToZ = "CATEGORY_A_TO_Z"
    case categoryZToA = "CATEGORY_Z_TO_A"

    var displayName: String {
        switch self {
        case .timeNewestFirst:
            return "time_newest_first".localized
        case .timeOldestFirst:
            return "time_oldest_first".localized
        case .amountHighToLow:
            return "amount_high_to_low".localized
        case .amountLowToHigh:
            return "amount_low_to_high".localized
        case .descriptionAToZ:
            return "description_a_to_z".localized
        case .descriptionZToA:
            return "description_z_to_a".localized
        case .categoryAToZ:
            return "category_a_to_z".localized
        case .categoryZToA:
            return "category_z_to_a".localized
        }
    }
}

struct MonthlyExpensesView: View {
    let currentMonth: Date
    let expenses: [Expense]
    let categories: [Category]
    let subCategories: [SubCategory]
    let editingExpenseId: String?
    let defaultCurrency: String
    let isDarkTheme: Bool
    let onExpenseUpdate: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    let onEditingChanged: (String?) -> Void

    @State private var searchText = ""
    @State private var showSortMenu = false
    @State private var currentSortType = ExpenseSortType.timeNewestFirst
    @State private var showSearchBar = false

    init(
        currentMonth: Date,
        expenses: [Expense],
        categories: [Category] = [],
        subCategories: [SubCategory] = [],
        editingExpenseId: String? = nil,
        defaultCurrency: String = "₺",
        isDarkTheme: Bool = true,
        onExpenseUpdate: @escaping (Expense) -> Void = { _ in },
        onExpenseDelete: @escaping (Expense) -> Void = { _ in },
        onEditingChanged: @escaping (String?) -> Void = { _ in }
    ) {
        self.currentMonth = currentMonth
        self.expenses = expenses
        self.categories = categories
        self.subCategories = subCategories
        self.editingExpenseId = editingExpenseId
        self.defaultCurrency = defaultCurrency
        self.isDarkTheme = isDarkTheme
        self.onExpenseUpdate = onExpenseUpdate
        self.onExpenseDelete = onExpenseDelete
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        VStack(spacing: 0) {
            if !baseMonthlyExpenses.isEmpty {
                controlsSection
                searchBarSection
            }
            monthHeaderSection
            expenseListSection
        }
    }
}

// MARK: - Computed Properties
extension MonthlyExpensesView {
    private var baseMonthlyExpenses: [Expense] {
        let calendar = Calendar.current
        guard let monthStart = calendar.startOfMonth(for: currentMonth),
              let monthEnd = calendar.endOfMonth(for: currentMonth) else {
            return []
        }

        return expenses.filter { expense in
            var currentDate = monthStart
            while currentDate <= monthEnd {
                if expense.isActiveOnDate(targetDate: currentDate) {
                    return true
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            return false
        }
    }

    private var filteredAndSortedExpenses: [Expense] {
        var filteredExpenses = baseMonthlyExpenses

        // Apply search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredExpenses = filteredExpenses.filter { expense in
                let category = categories.first { $0.id == expense.categoryId }
                let subCategory = subCategories.first { $0.id == expense.subCategoryId }

                return expense.description.localizedCaseInsensitiveContains(searchText) ||
                       "\(expense.amount)".contains(searchText) ||
                       (category?.name.localizedCaseInsensitiveContains(searchText) == true) ||
                       (subCategory?.name.localizedCaseInsensitiveContains(searchText) == true)
            }
        }

        // Apply sorting
        return sortExpenses(filteredExpenses, by: currentSortType)
    }

    private var monthHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: currentMonth)
    }
}

// MARK: - View Components
extension MonthlyExpensesView {
    private var controlsSection: some View {
        HStack {
            controlButtons
            Spacer()
            resultsCountText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var controlButtons: some View {
        HStack(spacing: 8) {
            searchButton
            sortButton
        }
    }

    private var searchButton: some View {
        Button(action: toggleSearchBar) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(showSearchBar ? AppColors.primaryOrange : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
    }

    private var sortButton: some View {
        Menu {
            ForEach(ExpenseSortType.allCases, id: \.self) { sortType in
                Button(action: {
                    currentSortType = sortType
                }) {
                    Text(sortType.displayName)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
        }
    }

    private var resultsCountText: some View {
        Text("results_count".localized.replacingOccurrences(of: "%d", with: "\(filteredAndSortedExpenses.count)"))
            .font(.system(size: 12))
            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
    }

    private var searchBarSection: some View {
        Group {
            if showSearchBar {
                SearchTextField(
                    text: $searchText,
                    placeholder: "search_placeholder".localized,
                    isDarkTheme: isDarkTheme
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var monthHeaderSection: some View {
        HStack {
            Text(monthHeaderText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            Spacer()
        }
    }

    private var expenseListSection: some View {
        Group {
            if filteredAndSortedExpenses.isEmpty {
                emptyStateView
            } else {
                expenseList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 48))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text(baseMonthlyExpenses.isEmpty ? "no_expenses_for_month".localized : "no_search_results".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var expenseList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredAndSortedExpenses, id: \.id) { expense in
                ExpenseRowView(
                    expense: expense,
                    onUpdate: onExpenseUpdate,
                    onEditingChanged: { isEditing in
                        onEditingChanged(isEditing ? expense.id : nil)
                    },
                    onDelete: {
                        onExpenseDelete(expense)
                    },
                    isCurrentlyEditing: editingExpenseId == expense.id,
                    dailyExpenseRatio: calculateDailyRatio(for: expense),
                    defaultCurrency: defaultCurrency,
                    isDarkTheme: isDarkTheme,
                    categories: categories,
                    subCategories: subCategories
                )
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Helper Methods
extension MonthlyExpensesView {
    private func toggleSearchBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSearchBar.toggle()
        }
        if !showSearchBar {
            searchText = ""
        }
    }

    private func sortExpenses(_ expenses: [Expense], by sortType: ExpenseSortType) -> [Expense] {
        switch sortType {
        case .amountHighToLow:
            return expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .amountLowToHigh:
            return expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        case .descriptionAToZ:
            return expenses.sorted { $0.description.lowercased() < $1.description.lowercased() }
        case .descriptionZToA:
            return expenses.sorted { $0.description.lowercased() > $1.description.lowercased() }
        case .categoryAToZ:
            return expenses.sorted { expense1, expense2 in
                let subCategory1 = subCategories.first { $0.id == expense1.subCategoryId }?.name.lowercased() ?? "zzz"
                let subCategory2 = subCategories.first { $0.id == expense2.subCategoryId }?.name.lowercased() ?? "zzz"
                return subCategory1 < subCategory2
            }
        case .categoryZToA:
            return expenses.sorted { expense1, expense2 in
                let subCategory1 = subCategories.first { $0.id == expense1.subCategoryId }?.name.lowercased() ?? ""
                let subCategory2 = subCategories.first { $0.id == expense2.subCategoryId }?.name.lowercased() ?? ""
                return subCategory1 > subCategory2
            }
        case .timeNewestFirst:
            return expenses.sorted { $0.date > $1.date }
        case .timeOldestFirst:
            return expenses.sorted { $0.date < $1.date }
        }
    }

    private func calculateDailyRatio(for expense: Expense) -> Double {
        // Simple implementation - could be enhanced with actual daily limit logic
        return 0.3
    }
}

struct SearchTextField: View {
    @Binding var text: String
    let placeholder: String
    let isDarkTheme: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct MonthlyExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleExpenses = [
            Expense(
                amount: 150.0,
                currency: "₺",
                categoryId: "food",
                subCategoryId: "restaurant",
                description: "Lunch at restaurant",
                date: Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            ),
            Expense(
                amount: 75.0,
                currency: "₺",
                categoryId: "transport",
                subCategoryId: "fuel",
                description: "Gas station",
                date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                dailyLimitAtCreation: 200.0,
                monthlyLimitAtCreation: 5000.0
            )
        ]

        let sampleCategories = Category.getDefaultCategories()
        let sampleSubCategories = SubCategory.getDefaultSubCategories()

        MonthlyExpensesView(
            currentMonth: Date(),
            expenses: sampleExpenses,
            categories: sampleCategories,
            subCategories: sampleSubCategories,
            isDarkTheme: true
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}