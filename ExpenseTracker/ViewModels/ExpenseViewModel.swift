//
//  ExpenseViewModel.swift
//  ExpenseTracker
//
//  Created by migration from Android ExpenseViewModel.kt
//

import Foundation
import Combine

class ExpenseViewModel: ObservableObject {
    public let preferencesManager: PreferencesManager
    private let expenseRepository: ExpenseRepository
    private let categoryRepository: CategoryRepository

    // MARK: - Published Properties

    @Published var expenses: [Expense] = []
    @Published var selectedDate = Date()
    @Published var showingOverLimitAlert = false
    @Published var editingExpenseId: String?

    // Category management
    @Published var categories: [Category] = []
    @Published var subCategories: [SubCategory] = []

    // Settings from PreferencesManager
    @Published var defaultCurrency = "₺"
    @Published var dailyLimit = ""
    @Published var monthlyLimit = ""
    @Published var theme = "dark"

    // Week navigation
    @Published var currentWeekOffset = 0
    @Published var weeklyHistoryData: [[DailyData]] = []

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(preferencesManager: PreferencesManager = PreferencesManager(),
         expenseRepository: ExpenseRepository = ExpenseRepository(),
         categoryRepository: CategoryRepository = CategoryRepository()) {
        self.preferencesManager = preferencesManager
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository

        setupBindings()
        loadInitialData()
    }

    private func setupBindings() {
        // Bind to preferences
        preferencesManager.$defaultCurrency
            .assign(to: \.defaultCurrency, on: self)
            .store(in: &cancellables)

        preferencesManager.$dailyLimit
            .assign(to: \.dailyLimit, on: self)
            .store(in: &cancellables)

        preferencesManager.$monthlyLimit
            .assign(to: \.monthlyLimit, on: self)
            .store(in: &cancellables)

        preferencesManager.$theme
            .assign(to: \.theme, on: self)
            .store(in: &cancellables)

        // Setup weekly history data generation
        Publishers.CombineLatest3($selectedDate, $currentWeekOffset, $expenses)
            .map { [weak self] selectedDate, weekOffset, allExpenses in
                self?.generateWeeklyHistoryData(selectedDate: selectedDate, weekOffset: weekOffset, allExpenses: allExpenses) ?? []
            }
            .assign(to: \.weeklyHistoryData, on: self)
            .store(in: &cancellables)
    }

    private func loadInitialData() {
        Task {
            await loadExpenses()
            await loadCategories()
            await initializeDefaultDataIfNeeded()

            // Force weekly data update after initial load
            await MainActor.run {
                selectedDate = selectedDate
            }
        }
    }

    // MARK: - Computed Properties

    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
    }

    private var monthlyLimitValue: Double {
        Double(monthlyLimit) ?? 10000.0
    }

    var isOverLimit: Bool {
        totalSpent > monthlyLimitValue && monthlyLimitValue > 0
    }

    private var dailyLimitValue: Double {
        Double(dailyLimit) ?? 0.0
    }

    var dailyProgressPercentage: Double {
        if dailyLimitValue <= 0 { return 0.0 }
        let selectedDayTotal = getSelectedDayTotal()
        return min(selectedDayTotal / dailyLimitValue, 1.0)
    }

    var isOverDailyLimit: Bool {
        let selectedDayTotal = getSelectedDayTotal()
        return selectedDayTotal > dailyLimitValue && dailyLimitValue > 0
    }

    var dailyExpensesByCategory: [CategoryExpense] {
        let selectedDayExpenses = getExpensesForDate(selectedDate)
        let selectedDayTotal = selectedDayExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }

        if selectedDayTotal <= 0 { return [] }

        var categoryTotals: [String: Double] = [:]

        for expense in selectedDayExpenses {
            categoryTotals[expense.categoryId, default: 0.0] += expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)
        }

        return categoryTotals.compactMap { (categoryId, amount) in
            guard let category = categories.first(where: { $0.id == categoryId }) else { return nil }
            return CategoryExpense(
                category: category,
                amount: amount,
                percentage: amount / selectedDayTotal
            )
        }.sorted { $0.amount > $1.amount }
    }

    var dailyHistoryData: [DailyData] {
        if weeklyHistoryData.count >= 2 {
            return weeklyHistoryData[1] // Return current week (middle week)
        }
        return []
    }

    // MARK: - Data Loading

    @MainActor
    private func loadExpenses() async {
        do {
            expenses = try await expenseRepository.getAllExpenses()
        } catch {
            print("Error loading expenses: \(error)")
        }
    }

    @MainActor
    private func loadCategories() async {
        do {
            categories = try await categoryRepository.getAllCategories()
            subCategories = try await categoryRepository.getAllSubCategories()
        } catch {
            print("Error loading categories: \(error)")
        }
    }

    private func initializeDefaultDataIfNeeded() async {
        do {
            try await categoryRepository.initializeDefaultDataIfNeeded()
            await loadCategories()
        } catch {
            print("Error initializing default data: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func getSelectedDayTotal() -> Double {
        return getExpensesForDate(selectedDate).reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
    }

    private func getExpensesForDate(_ date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            calendar.isDate(expense.date, inSameDayAs: date)
        }
    }

    // MARK: - Weekly History Data Generation

    private func generateWeeklyHistoryData(selectedDate: Date, weekOffset: Int, allExpenses: [Expense]) -> [[DailyData]] {
        let calendar = Calendar.current

        // Calculate the start of the week (Monday) for the selected date
        let startOfSelectedWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate

        // The baseWeek should be the currently displayed week
        let baseWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfSelectedWeek) ?? startOfSelectedWeek

        // Generate 3 weeks: previous (-1), current (0), next (+1)
        return (-1...1).map { weekIndex in
            let startOfWeek = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: baseWeek) ?? baseWeek

            // Generate 7 days for this week
            return (0...6).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) ?? startOfWeek
                let dayExpenses = getExpensesForDate(date)
                let totalAmount = dayExpenses.reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
                let progressAmount = dayExpenses.filter { $0.recurrenceType == .NONE }
                    .reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
                let expenseCount = dayExpenses.count

                return DailyData(
                    date: date,
                    totalAmount: totalAmount,
                    progressAmount: progressAmount,
                    expenseCount: expenseCount,
                    dailyLimit: dailyLimitValue
                )
            }
        }
    }

    // MARK: - Date Navigation

    func updateSelectedDate(_ date: Date) {
        selectedDate = date
        currentWeekOffset = 0
    }

    // MARK: - Debug Methods

    func printAllExpenses() {
        print("=== ALL EXPENSES (\(expenses.count)) ===")
        expenses.sorted { $0.date > $1.date }.forEach { expense in
            print("ID: \(expense.id)")
            print("Amount: \(expense.amount) \(expense.currency)")
            print("Description: \(expense.description)")
            print("Date: \(expense.date)")
            print("ExchangeRate: \(expense.exchangeRate ?? 0)")
            print("---")
        }
    }

    func navigateToWeek(direction: Int) {
        currentWeekOffset += direction
    }

    func resetWeekOffset() {
        currentWeekOffset = 0
    }

    // MARK: - Expense Management

    func addExpense(_ expense: Expense) {
        Task {
            do {
                if expense.recurrenceType != .NONE && expense.recurrenceGroupId != nil {
                    let recurringExpenses = generateRecurringExpenses(expense)
                    // Batch insert to avoid context conflicts
                    for batch in recurringExpenses.chunked(into: 50) {
                        for individualExpense in batch {
                            try await expenseRepository.insertExpense(individualExpense)
                        }
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                    }
                } else {
                    try await expenseRepository.insertExpense(expense)
                }

                await loadExpenses()

                // Force UI update
                await MainActor.run {
                    selectedDate = selectedDate
                }

                // Check if over limit
                if !isOverLimit && totalSpent > monthlyLimitValue && monthlyLimitValue > 0 {
                    await MainActor.run {
                        showingOverLimitAlert = true
                    }
                }
            } catch {
                print("Error adding expense: \(error)")
            }
        }
    }

    func updateExpense(_ expense: Expense) {
        Task {
            do {
                try await expenseRepository.updateExpense(expense)
                await loadExpenses()

                // Force UI update
                await MainActor.run {
                    selectedDate = selectedDate
                }
            } catch {
                print("Error updating expense: \(error)")
            }
        }
    }

    func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await expenseRepository.deleteExpense(expense)
                await loadExpenses()

                // Force UI update
                await MainActor.run {
                    selectedDate = selectedDate
                }
            } catch {
                print("Error deleting expense: \(error)")
            }
        }
    }

    // MARK: - Recurring Expenses

    private func generateRecurringExpenses(_ baseExpense: Expense) -> [Expense] {
        var expenses: [Expense] = []
        let calendar = Calendar.current
        let endDate = baseExpense.endDate ?? calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        var currentDate = baseExpense.date

        while currentDate <= endDate {
            if isRecurringExpenseActiveOnDate(baseExpense, currentDate) {
                let individualExpense = Expense(
                    id: UUID().uuidString,
                    amount: baseExpense.amount,
                    currency: baseExpense.currency,
                    categoryId: baseExpense.categoryId,
                    subCategoryId: baseExpense.subCategoryId,
                    description: baseExpense.description,
                    date: currentDate,
                    dailyLimitAtCreation: baseExpense.dailyLimitAtCreation,
                    monthlyLimitAtCreation: baseExpense.monthlyLimitAtCreation,
                    exchangeRate: baseExpense.exchangeRate,
                    recurrenceType: baseExpense.recurrenceType,
                    endDate: baseExpense.endDate,
                    recurrenceGroupId: baseExpense.recurrenceGroupId
                )
                expenses.append(individualExpense)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return expenses
    }

    private func isRecurringExpenseActiveOnDate(_ expense: Expense, _ targetDate: Date) -> Bool {
        let calendar = Calendar.current

        // Check if target date is before start date
        if targetDate < calendar.startOfDay(for: expense.date) {
            return false
        }

        // Check if target date is after end date
        if let endDate = expense.endDate, targetDate > endDate {
            return false
        }

        switch expense.recurrenceType {
        case .DAILY:
            return true
        case .WEEKDAYS:
            let weekday = calendar.component(.weekday, from: targetDate)
            return weekday >= 2 && weekday <= 6 // Monday = 2, Friday = 6
        case .WEEKLY:
            let startWeekday = calendar.component(.weekday, from: expense.date)
            let targetWeekday = calendar.component(.weekday, from: targetDate)
            return startWeekday == targetWeekday
        case .MONTHLY:
            let startDay = calendar.component(.day, from: expense.date)
            let targetDay = calendar.component(.day, from: targetDate)
            return startDay == targetDay
        case .NONE:
            return false
        }
    }

    // MARK: - Category Management

    func createCustomCategory(name: String, colorHex: String, iconName: String) {
        Task {
            do {
                let category = Category(
                    id: UUID().uuidString,
                    name: name,
                    colorHex: colorHex, iconName: iconName,
                    isCustom: true
                )
                try await categoryRepository.insertCategory(category)
                await loadCategories()
            } catch {
                print("Error creating category: \(error)")
            }
        }
    }

    func createCustomSubCategory(name: String, categoryId: String) {
        Task {
            do {
                let subCategory = SubCategory(
                    id: UUID().uuidString,
                    name: name, categoryId: categoryId,
                    isCustom: true
                )
                try await categoryRepository.insertSubCategory(subCategory)
                await loadCategories()
            } catch {
                print("Error creating subcategory: \(error)")
            }
        }
    }

    func updateCategory(_ category: Category) {
        Task {
            do {
                try await categoryRepository.updateCategory(category)
                await loadCategories()
            } catch {
                print("Error updating category: \(error)")
            }
        }
    }

    func updateSubCategory(_ subCategory: SubCategory) {
        Task {
            do {
                try await categoryRepository.updateSubCategory(subCategory)
                await loadCategories()
            } catch {
                print("Error updating subcategory: \(error)")
            }
        }
    }

    func deleteCategory(_ category: Category) {
        Task {
            do {
                try await categoryRepository.deleteCategory(category)
                await loadCategories()
            } catch {
                print("Error deleting category: \(error)")
            }
        }
    }

    func deleteSubCategory(_ subCategory: SubCategory) {
        Task {
            do {
                try await categoryRepository.deleteSubCategory(subCategory)
                await loadCategories()
            } catch {
                print("Error deleting subcategory: \(error)")
            }
        }
    }

    // MARK: - Helper Methods for UI Components

    func getDailyExpenseRatio(_ expense: Expense) -> Double {
        let dailyTotal = getExpensesForDate(expense.date).reduce(0) { $0 + $1.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency) }
        if dailyLimitValue <= 0 { return 0.0 }
        return min(dailyTotal / dailyLimitValue, 1.0)
    }

    // MARK: - Recurring Expense Management

    func deleteRecurringExpenseFromDate(_ expense: Expense, fromDate: Date) {
        guard let groupId = expense.recurrenceGroupId else {
            deleteExpense(expense)
            return
        }

        Task {
            do {
                // Delete all instances from the selected date onwards
                let calendar = Calendar.current
                let expensesToDelete = expenses.filter { exp in
                    exp.recurrenceGroupId == groupId &&
                    exp.date >= calendar.startOfDay(for: fromDate)
                }

                for expenseToDelete in expensesToDelete {
                    try await expenseRepository.deleteExpense(expenseToDelete)
                }

                await loadExpenses()
                await MainActor.run {
                    selectedDate = selectedDate
                }
            } catch {
                print("Error deleting recurring expenses: \(error)")
            }
        }
    }

    func updateRecurringExpenseFromDate(_ expense: Expense, fromDate: Date) {
        guard let groupId = expense.recurrenceGroupId else {
            updateExpense(expense)
            return
        }

        Task {
            do {
                // Update all instances from the selected date onwards
                let calendar = Calendar.current
                let expensesToUpdate = expenses.filter { exp in
                    exp.recurrenceGroupId == groupId &&
                    exp.date >= calendar.startOfDay(for: fromDate)
                }

                for expenseToUpdate in expensesToUpdate {
                    let updatedExpense = Expense(
                        id: expenseToUpdate.id,
                        amount: expense.amount,
                        currency: expenseToUpdate.currency,
                        categoryId: expenseToUpdate.categoryId,
                        subCategoryId: expenseToUpdate.subCategoryId,
                        description: expense.description,
                        date: expenseToUpdate.date,
                        dailyLimitAtCreation: expenseToUpdate.dailyLimitAtCreation,
                        monthlyLimitAtCreation: expenseToUpdate.monthlyLimitAtCreation,
                        exchangeRate: expense.exchangeRate,
                        recurrenceType: expenseToUpdate.recurrenceType,
                        endDate: expense.endDate,
                        recurrenceGroupId: expenseToUpdate.recurrenceGroupId
                    )
                    try await expenseRepository.updateExpense(updatedExpense)
                }

                await loadExpenses()
                await MainActor.run {
                    selectedDate = selectedDate
                }
            } catch {
                print("Error updating recurring expenses: \(error)")
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct CategoryExpense: Equatable {
    let category: Category
    let amount: Double
    let percentage: Double
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
