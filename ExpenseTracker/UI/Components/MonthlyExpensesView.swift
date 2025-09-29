//
//  MonthlyExpensesView.swift
//  ExpenseTracker
//
//  COMPLETE REWRITE - Exactly matching Android MonthlyExpensesView.kt
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

struct MonthlyExpensesView:  View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    let currentMonth: Date
    let expenses: [Expense]
    let isDarkTheme: Bool

    @State private var searchText = ""
    @State private var showSortMenu = false
    @State private var currentSortType = ExpenseSortType.timeNewestFirst
    @State private var showSearchBar = false

    var body: some View {
        VStack(spacing: 0) {
            // Search and Sort controls (only show if base expenses exist)
            if !baseMonthlyExpenses.isEmpty {
                searchAndSortControls
                searchBarSection
            }

            // Month header
            monthHeaderSection

            // Expenses list
            expenseListSection
        }
    }
}

// MARK: - Computed Properties
extension MonthlyExpensesView {
    private var baseMonthlyExpenses: [Expense] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth

        return expenses.filter { expense in
            var currentDate = startOfMonth
            while currentDate <= endOfMonth {
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

        // Apply search filter (exactly like Kotlin)
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredExpenses = filteredExpenses.filter { expense in
                let category = viewModel.categories.first { $0.id == expense.categoryId }
                let subCategory = viewModel.subCategories.first { $0.id == expense.subCategoryId }

                return expense.description.localizedCaseInsensitiveContains(searchText) ||
                       "\(expense.amount)".contains(searchText) ||
                       (category?.name.localizedCaseInsensitiveContains(searchText) == true) ||
                       (subCategory?.name.localizedCaseInsensitiveContains(searchText) == true)
            }
        }

        // Apply sorting (exactly like Kotlin)
        return sortExpenses(filteredExpenses)
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
    private var searchAndSortControls: some View {
        HStack {
            // Left side controls
            HStack(spacing: 8) {
                // Search toggle button
                Button(action: toggleSearchBar) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(showSearchBar ? AppColors.primaryOrange : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                }

                // Sort button with dropdown menu
                Menu {
                    ForEach(ExpenseSortType.allCases, id: \.rawValue) { sortType in
                        Button(sortType.displayName) {
                            currentSortType = sortType
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                }

                // Results count
                Text("results_count".localized.replacingOccurrences(of: "%d", with: "\(filteredAndSortedExpenses.count)"))
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }

            Spacer()

            // Month header (moved here to match Kotlin layout)
            Text(monthHeaderText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var searchBarSection: some View {
        if showSearchBar {
            // Search bar with animated visibility
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .font(.system(size: 20))

                TextField("search_expenses_placeholder".localized, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var monthHeaderSection: some View {
        EmptyView() // Month header moved to searchAndSortControls
    }

    private var expenseListSection: some View {
        Group {
            if filteredAndSortedExpenses.isEmpty {
                emptyStateView
            } else {
                expensesList
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "plus")
                .font(.system(size: 60))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Text(searchText.isEmpty ? "no_expenses_this_month".localized : "no_search_results".localized)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Text(searchText.isEmpty ? "add_expense_for_month".localized : "search_no_results_description".localized.replacingOccurrences(of: "%@", with: searchText))
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var expensesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredAndSortedExpenses, id: \.id) { expense in
                    ExpenseRowView(
                        expense: expense,
                        onUpdate: { updatedExpense in
                            viewModel.updateExpense(updatedExpense)
                        },
                        onEditingChanged: { isEditing in
                            if isEditing {
                                viewModel.editingExpenseId = expense.id
                            } else {
                                viewModel.editingExpenseId = nil
                            }
                        },
                        onDelete: {
                            viewModel.deleteExpense(expense)
                        },
                        isCurrentlyEditing: viewModel.editingExpenseId == expense.id,
                        dailyExpenseRatio: viewModel.getDailyExpenseRatio(expense),
                        defaultCurrency: viewModel.defaultCurrency,
                        isDarkTheme: isDarkTheme,
                        categories: viewModel.categories,
                        subCategories: viewModel.subCategories
                    )
                    .environmentObject(viewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
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

    private func sortExpenses(_ expenses: [Expense]) -> [Expense] {
        switch currentSortType {
        case .amountHighToLow:
            return expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .amountLowToHigh:
            return expenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .descriptionAToZ:
            return expenses.sorted { $0.description.lowercased() < $1.description.lowercased() }
        case .descriptionZToA:
            return expenses.sorted { $0.description.lowercased() > $1.description.lowercased() }
        case .categoryAToZ:
            return expenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }?.name.lowercased() ?? "zzz"
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }?.name.lowercased() ?? "zzz"
                return subCategory1 < subCategory2
            }
        case .categoryZToA:
            return expenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }?.name.lowercased() ?? ""
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }?.name.lowercased() ?? ""
                return subCategory1 > subCategory2
            }
        case .timeNewestFirst:
            return expenses.sorted { $0.date > $1.date }
        case .timeOldestFirst:
            return expenses.sorted { $0.date < $1.date }
        }
    }
}

// MARK: - Preview
struct MonthlyExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()
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
            )
        ]

        MonthlyExpensesView(
            currentMonth: Date(),
            expenses: sampleExpenses,
            isDarkTheme: true
        )
        .environmentObject(viewModel)
    }
}
