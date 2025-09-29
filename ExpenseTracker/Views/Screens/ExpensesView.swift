//
//  ExpensesView.swift
//  ExpenseTracker
//
//  Created by migration from Android ExpensesScreen.kt
//

import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var viewModel: ExpenseViewModel

    @State private var showingAddExpense = false
    @State private var showingSettings = false
    @State private var showingMonthlyCalendar = false
    @State private var showingRecurringExpenses = false
    @State private var currentCalendarMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()

    // Daily category detail bottom sheet state
    @State private var showingDailyCategoryDetail = false
    @State private var selectedCategoryForDetail: Category?

    // Search and sorting state
    @State private var searchText = ""
    @State private var showSortMenu = false
    @State private var currentSortType: ExpenseSortType = .timeNewestFirst
    @State private var showSearchBar = false

    private var isDarkTheme: Bool {
        viewModel.theme == "dark"
    }

    // Get selected date expenses (including recurring expenses)
    private var baseSelectedDateExpenses: [Expense] {
        viewModel.expenses.filter { expense in
            expense.isActiveOnDate(targetDate: viewModel.selectedDate)
        }
    }

    // Filter and sort expenses
    private var selectedDateExpenses: [Expense] {
        var filteredExpenses = baseSelectedDateExpenses

        // Apply search filter
        if !searchText.isEmpty {
            filteredExpenses = filteredExpenses.filter { expense in
                let category = viewModel.categories.first { $0.id == expense.categoryId }
                let subCategory = viewModel.subCategories.first { $0.id == expense.subCategoryId }

                return expense.description.localizedCaseInsensitiveContains(searchText) == true ||
                       String(expense.amount).contains(searchText) ||
                       category?.name.localizedCaseInsensitiveContains(searchText) == true ||
                       subCategory?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply sorting
        switch currentSortType {
        case .amountHighToLow:
            return filteredExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) > $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .amountLowToHigh:
            return filteredExpenses.sorted { $0.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) < $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
        case .descriptionAToZ:
            return filteredExpenses.sorted { ($0.description).lowercased() < ($1.description).lowercased() }
        case .descriptionZToA:
            return filteredExpenses.sorted { ($0.description).lowercased() > ($1.description).lowercased() }
        case .categoryAToZ:
            return filteredExpenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }
                return (subCategory1?.name ?? "zzz").lowercased() < (subCategory2?.name ?? "zzz").lowercased()
            }
        case .categoryZToA:
            return filteredExpenses.sorted { expense1, expense2 in
                let subCategory1 = viewModel.subCategories.first { $0.id == expense1.subCategoryId }
                let subCategory2 = viewModel.subCategories.first { $0.id == expense2.subCategoryId }
                return (subCategory1?.name ?? "").lowercased() > (subCategory2?.name ?? "").lowercased()
            }
        case .timeNewestFirst:
            return filteredExpenses.sorted { $0.date > $1.date }
        case .timeOldestFirst:
            return filteredExpenses.sorted { $0.date < $1.date }
        }
    }

    var body: some View {
        ZStack {
            ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                // Debug button (temporary)
                Button("Debug DB") {
                    viewModel.printAllExpenses()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)

                // Daily History
                DailyHistoryView(
                    weeklyData: viewModel.weeklyHistoryData,
                    selectedDate: viewModel.selectedDate,
                    onDateSelected: { date in
                        print("ExpensesView: Date selected: \(date)")
                        viewModel.updateSelectedDate(date)
                    },
                    onWeekNavigate: { direction in
                        viewModel.navigateToWeek(direction: direction)
                    },
                    isDarkTheme: isDarkTheme
                )

                Spacer().frame(height: 6)

                // Charts TabView
                chartsTabView

                // Search and Sort controls (only show if there are expenses)
                if !baseSelectedDateExpenses.isEmpty {
                    searchAndSortSection
                }

                // Animated Search Bar
                if showSearchBar {
                    searchSection
                }

                // Expense List
                expenseListSection
            }

            // Floating Action Buttons (Over Charts)
            floatingActionButtons

            // Over Limit Alert (Custom Card at top)
            if viewModel.showingOverLimitAlert {
                VStack {
                    HStack {
                        Text("monthly_limit_exceeded".localized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)

                        Spacer()

                        Button("✕") {
                            // Handle alert dismissal
                        }
                        .foregroundColor(.white)
                    }
                    .padding(16)
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            addExpenseSheet
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .sheet(isPresented: $showingMonthlyCalendar) {
            monthlyCalendarSheet
        }
        .sheet(isPresented: $showingRecurringExpenses) {
            recurringExpensesSheet
        }
        .sheet(isPresented: $showingDailyCategoryDetail) {
            dailyCategoryDetailSheet
        }
    }
}

// MARK: - View Components
extension ExpensesView {
    private var chartsTabView: some View {
        TabView {
            // Monthly Progress Ring
            MonthlyProgressRingView(
                totalSpent: getMonthlyTotal(),
                progressPercentage: getMonthlyProgressPercentage(),
                isOverLimit: isMonthlyOverLimit(),
                onTap: { showingMonthlyCalendar = true },
                currency: viewModel.defaultCurrency,
                isDarkTheme: isDarkTheme,
                month: monthFormatter.string(from: currentCalendarMonth),
                selectedDate: viewModel.selectedDate
            )
            .tag(0)

            // Daily Progress Ring
            DailyProgressRingView(
                dailyProgressPercentage: viewModel.dailyProgressPercentage,
                isOverDailyLimit: viewModel.isOverDailyLimit,
                selectedDateTotal: getSelectedDayTotal(),
                currency: viewModel.defaultCurrency,
                isDarkTheme: isDarkTheme
            )
            .tag(1)

            // Category Distribution
            CategoryDistributionChart(
                categoryExpenses: viewModel.dailyExpensesByCategory,
                onCategoryClick: { category in
                    selectedCategoryForDetail = category
                    showingDailyCategoryDetail = true
                }, isDarkTheme: isDarkTheme
            )
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 180)
        .padding(.horizontal, 20)
    }

    private var searchAndSortSection: some View {
        HStack(spacing: 8) {
            // Search toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSearchBar.toggle()
                    if !showSearchBar {
                        searchText = ""
                    }
                }
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(showSearchBar ? AppColors.primaryOrange : ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
            .frame(width: 44, height: 44)

            // Sort Menu
            Menu {
                ForEach(ExpenseSortType.allCases, id: \.rawValue) { sortType in
                    Button(sortType.displayName) {
                        currentSortType = sortType
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 20))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
            }
            .frame(width: 44, height: 44)

            // Search results count
            if !searchText.isEmpty {
                Text("results_count".localized.replacingOccurrences(of: "%d", with: "\(selectedDateExpenses.count)"))
                    .font(.system(size: 12))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var floatingActionButtons: some View {
        VStack {
            Spacer().frame(height: 200) // Position over charts

            HStack {
                // Settings Button (Left)
                VStack {
                    Button(action: { showingSettings = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(red: 0.063, green: 0.063, blue: 0.063), Color(red: 0.063, green: 0.063, blue: 0.063)],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "gearshape")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer().frame(height: 35) // Spacing between buttons
                }

                Spacer()

                // Right side buttons (vertical stack)
                VStack(spacing: 12) {
                    // Recurring Expenses Button
                    Button(action: { showingRecurringExpenses = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(red: 0.247, green: 0.318, blue: 0.710), Color(red: 0.612, green: 0.153, blue: 0.690)],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "repeat")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        }
                    }

                    // Add Expense Button
                    Button(action: { showingAddExpense = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(red: 1.0, green: 0.584, blue: 0.0), Color(red: 1.0, green: 0.231, blue: 0.188)],
                                        center: .center,
                                        startRadius: 5,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)

                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            TextField("search_placeholder".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14))
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var expenseListSection: some View {
        VStack(spacing: 0) {
            if selectedDateExpenses.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(selectedDateExpenses, id: \.id) { expense in
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
                                dailyExpenseRatio: getDailyExpenseRatio(expense),
                                defaultCurrency: viewModel.defaultCurrency,
                                isDarkTheme: isDarkTheme,
                                categories: viewModel.categories,
                                subCategories: viewModel.subCategories
                            )
                            .environmentObject(viewModel)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "no_expenses_today".localized : "no_search_results_found".localized)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)

                Text(searchText.isEmpty ? "first_expense_hint".localized : "no_search_results_description".localized.replacingOccurrences(of: "%s", with: searchText))
                    .font(.system(size: 14))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Sheet Views
    private var addExpenseSheet: some View {
        AddExpenseView(
            selectedDate: viewModel.selectedDate,
            defaultCurrency: viewModel.defaultCurrency,
            dailyLimit: viewModel.dailyLimit,
            monthlyLimit: viewModel.monthlyLimit,
            isDarkTheme: isDarkTheme,
            onExpenseAdded: { expense in
                if let editingId = viewModel.editingExpenseId {
                    // Update existing expense
                    let updatedExpense = Expense(
                        id: editingId,
                        amount: expense.amount,
                        currency: expense.currency,
                        categoryId: expense.categoryId,
                        subCategoryId: expense.subCategoryId,
                        description: expense.description,
                        date: expense.date,
                        dailyLimitAtCreation: expense.dailyLimitAtCreation,
                        monthlyLimitAtCreation: expense.monthlyLimitAtCreation,
                        exchangeRate: expense.exchangeRate,
                        recurrenceType: expense.recurrenceType,
                        endDate: expense.endDate,
                        recurrenceGroupId: expense.recurrenceGroupId
                    )
                    viewModel.updateExpense(updatedExpense)
                    viewModel.editingExpenseId = nil
                } else {
                    // Add new expense
                    viewModel.addExpense(expense)
                }
            },
            onDismiss: {
                showingAddExpense = false
                viewModel.editingExpenseId = nil
            },
            editingExpense: viewModel.editingExpenseId != nil ? viewModel.expenses.first { $0.id == viewModel.editingExpenseId } : nil
        )
        .environmentObject(viewModel)
    }

    private var settingsSheet: some View {
        SettingsView(onDismiss: { showingSettings = false })
            .environmentObject(viewModel)
    }

    private var monthlyCalendarSheet: some View {
        MonthlyCalendarBottomSheet(
            selectedMonth: currentCalendarMonth,
            onDismiss: { showingMonthlyCalendar = false }
        )
        .environmentObject(viewModel)
    }

    private var recurringExpensesSheet: some View {
        RecurringExpensesView(onDismiss: { showingRecurringExpenses = false })
            .environmentObject(viewModel)
    }

    private var dailyCategoryDetailSheet: some View {
        DailyCategoryDetailBottomSheet(
            category: selectedCategoryForDetail ?? Category.getDefaultCategories()[0],
            selectedDateExpenses: selectedDateExpenses,
            subCategories: viewModel.subCategories,
            selectedDate: viewModel.selectedDate,
            defaultCurrency: viewModel.defaultCurrency,
            isDarkTheme: isDarkTheme,
            onDismiss: {
                showingDailyCategoryDetail = false
                selectedCategoryForDetail = nil
            }
        )
        .environmentObject(viewModel)
    }
}

// MARK: - Helper Methods
extension ExpensesView {
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }

    private func getMonthlyTotal() -> Double {
        let calendar = Calendar.current
        let month = calendar.dateInterval(of: .month, for: currentCalendarMonth)
        guard let monthRange = month else { return 0.0 }

        return viewModel.expenses
            .filter {
                calendar.isDate($0.date, inSameDayAs: monthRange.start) ||
                (monthRange.contains($0.date))
            }
            .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
    }

    private func getMonthlyProgressPercentage() -> Double {
        let monthlyLimit = Double(viewModel.monthlyLimit) ?? 0.0
        guard monthlyLimit > 0 else { return 0.0 }
        return min(getMonthlyTotal() / monthlyLimit, 1.0)
    }

    private func isMonthlyOverLimit() -> Bool {
        let monthlyLimit = Double(viewModel.monthlyLimit) ?? 0.0
        return getMonthlyTotal() > monthlyLimit && monthlyLimit > 0
    }

    private func getSelectedDayTotal() -> Double {
        let calendar = Calendar.current
        return viewModel.expenses
            .filter { calendar.isDate($0.date, inSameDayAs: viewModel.selectedDate) }
            .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency) }
    }

    private func getDailyExpenseRatio(_ expense: Expense) -> Double {
        let selectedDayTotal = getSelectedDayTotal()
        guard selectedDayTotal > 0 else { return 0.0 }
        let expenseAmount = expense.getAmountInDefaultCurrency(defaultCurrency: viewModel.defaultCurrency)
        return expenseAmount / selectedDayTotal
    }
}

// MARK: - Preview
struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ExpenseViewModel()

        ExpensesView()
            .environmentObject(viewModel)
    }
}
