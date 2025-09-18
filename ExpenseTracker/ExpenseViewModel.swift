//
//  ExpenseViewModel.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive expense view model with state management for SwiftUI views
/// Provides reactive state management for expense operations, filtering, search, and analytics
/// Integrates with ExpenseRepository for business logic and CategoryRepository for categorization
@MainActor
class ExpenseViewModel: ObservableObject {

    // MARK: - Dependencies

    private let expenseRepository: ExpenseRepository
    private let categoryRepository: CategoryRepository
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties - Data State

    /// All expenses with current filtering applied
    @Published var expenses: [Expense] = []

    /// Filtered and searched expenses for display
    @Published var filteredExpenses: [Expense] = []

    /// Today's expenses
    @Published var todayExpenses: [Expense] = []

    /// This month's expenses
    @Published var thisMonthExpenses: [Expense] = []

    /// Recurring expense templates
    @Published var recurringTemplates: [Expense] = []

    /// Upcoming recurring expenses
    @Published var upcomingRecurringExpenses: [Expense] = []

    /// Selected expenses for bulk operations
    @Published var selectedExpenses: Set<String> = []

    // MARK: - Published Properties - Filter and Search State

    /// Current search text
    @Published var searchText: String = "" {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Selected date for filtering
    @Published var selectedDate: Date = Date() {
        didSet {
            loadExpensesForSelectedDate()
        }
    }

    /// Date range filter start date
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date() {
        didSet {
            if isDateRangeFilterActive {
                applyFiltersAndSearch()
            }
        }
    }

    /// Date range filter end date
    @Published var endDate: Date = Date() {
        didSet {
            if isDateRangeFilterActive {
                applyFiltersAndSearch()
            }
        }
    }

    /// Selected category filters
    @Published var selectedCategoryIds: Set<String> = [] {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Selected subcategory filters
    @Published var selectedSubCategoryIds: Set<String> = [] {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Selected status filter
    @Published var selectedStatus: ExpenseStatus? = nil {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Current sort field
    @Published var sortBy: ExpenseSortField = .date {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Sort direction
    @Published var sortAscending: Bool = false {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Amount range filter
    @Published var amountRange: ClosedRange<Double> = 0...10000 {
        didSet {
            if isAmountFilterActive {
                applyFiltersAndSearch()
            }
        }
    }

    /// Whether date range filter is active
    @Published var isDateRangeFilterActive: Bool = false {
        didSet {
            applyFiltersAndSearch()
        }
    }

    /// Whether amount filter is active
    @Published var isAmountFilterActive: Bool = false {
        didSet {
            applyFiltersAndSearch()
        }
    }

    // MARK: - Published Properties - UI State

    /// Loading state for various operations
    @Published var isLoading: Bool = false

    /// Loading state specifically for creating expenses
    @Published var isCreatingExpense: Bool = false

    /// Loading state for updating expenses
    @Published var isUpdatingExpense: Bool = false

    /// Loading state for deleting expenses
    @Published var isDeletingExpense: Bool = false

    /// Loading state for analytics
    @Published var isLoadingAnalytics: Bool = false

    /// Current error message
    @Published var errorMessage: String? = nil

    /// Success message
    @Published var successMessage: String? = nil

    /// Whether error alert should be shown
    @Published var showingErrorAlert: Bool = false

    /// Whether success alert should be shown
    @Published var showingSuccessAlert: Bool = false

    /// Whether add expense sheet is presented
    @Published var showingAddExpense: Bool = false

    /// Whether edit expense sheet is presented
    @Published var showingEditExpense: Bool = false

    /// Whether expense details view is presented
    @Published var showingExpenseDetails: Bool = false

    /// Whether filters sheet is presented
    @Published var showingFilters: Bool = false

    /// Whether bulk operations sheet is presented
    @Published var showingBulkOperations: Bool = false

    /// Whether export sheet is presented
    @Published var showingExport: Bool = false

    /// Whether confirmation dialog is shown
    @Published var showingConfirmationDialog: Bool = false

    /// Selection mode for bulk operations
    @Published var isInSelectionMode: Bool = false

    // MARK: - Published Properties - Form State

    /// Currently selected expense for editing/viewing
    @Published var selectedExpense: Expense? = nil

    /// Form state for creating new expense
    @Published var newExpenseForm: ExpenseFormState = ExpenseFormState()

    /// Form state for editing existing expense
    @Published var editExpenseForm: ExpenseFormState = ExpenseFormState()

    /// Form validation errors
    @Published var formErrors: [String: String] = [:]

    /// Whether form is valid
    @Published var isFormValid: Bool = false

    // MARK: - Published Properties - Analytics and Summary

    /// Current month analytics
    @Published var monthlyAnalytics: ExpenseAnalytics? = nil

    /// Current spending summary
    @Published var spendingSummary: SpendingSummary? = nil

    /// Daily spending totals for current month
    @Published var dailyTotals: [String: Double] = [:]

    /// Category spending breakdown
    @Published var categoryBreakdown: [String: Double] = [:]

    /// Weekly spending trend
    @Published var weeklyTrend: [Double] = []

    /// Monthly spending trend (last 6 months)
    @Published var monthlyTrend: [Double] = []

    /// Budget progress for categories
    @Published var budgetProgress: [String: BudgetProgress] = [:]

    // MARK: - Published Properties - Limits and Notifications

    /// Daily limit progress
    @Published var dailyLimitProgress: Double = 0.0

    /// Monthly limit progress
    @Published var monthlyLimitProgress: Double = 0.0

    /// Yearly limit progress
    @Published var yearlyLimitProgress: Double = 0.0

    /// Whether daily limit is exceeded
    @Published var isDailyLimitExceeded: Bool = false

    /// Whether monthly limit is exceeded
    @Published var isMonthlyLimitExceeded: Bool = false

    /// Whether yearly limit is exceeded
    @Published var isYearlyLimitExceeded: Bool = false

    /// Pending recurring expenses count
    @Published var pendingRecurringCount: Int = 0

    /// Over-limit notification messages
    @Published var limitNotifications: [LimitNotification] = []

    // MARK: - Published Properties - Categories

    /// Available categories for selection
    @Published var availableCategories: [Category] = []

    /// Available subcategories for selected category
    @Published var availableSubCategories: [SubCategory] = []

    /// Category analytics
    @Published var categoryAnalytics: [CategoryAnalytics] = []

    // MARK: - Computed Properties

    /// Total amount of filtered expenses
    var totalFilteredAmount: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    /// Count of filtered expenses
    var filteredExpenseCount: Int {
        filteredExpenses.count
    }

    /// Average expense amount
    var averageExpenseAmount: Double {
        guard !filteredExpenses.isEmpty else { return 0 }
        return totalFilteredAmount / Double(filteredExpenses.count)
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        !selectedCategoryIds.isEmpty ||
        !selectedSubCategoryIds.isEmpty ||
        selectedStatus != nil ||
        isDateRangeFilterActive ||
        isAmountFilterActive
    }

    /// Formatted total amount for display
    var formattedTotalAmount: String {
        formatCurrency(totalFilteredAmount)
    }

    /// Today's spending formatted
    var formattedTodaySpending: String {
        let todayAmount = todayExpenses.reduce(0) { $0 + $1.amount }
        return formatCurrency(todayAmount)
    }

    /// This month's spending formatted
    var formattedMonthSpending: String {
        let monthAmount = thisMonthExpenses.reduce(0) { $0 + $1.amount }
        return formatCurrency(monthAmount)
    }

    // MARK: - Initialization

    init(
        expenseRepository: ExpenseRepository = ExpenseRepository(),
        categoryRepository: CategoryRepository = CategoryRepository(),
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.settingsManager = settingsManager
        setupBindings()
        loadInitialData()
    }

    // MARK: - Setup Methods

    private func setupBindings() {
        // Bind to repository data changes
        expenseRepository.$recentExpenses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] expenses in
                self?.expenses = expenses
                self?.applyFiltersAndSearch()
            }
            .store(in: &cancellables)

        expenseRepository.$todayExpenses
            .receive(on: DispatchQueue.main)
            .assign(to: \.todayExpenses, on: self)
            .store(in: &cancellables)

        expenseRepository.$thisMonthExpenses
            .receive(on: DispatchQueue.main)
            .assign(to: \.thisMonthExpenses, on: self)
            .store(in: &cancellables)

        expenseRepository.$recurringTemplates
            .receive(on: DispatchQueue.main)
            .assign(to: \.recurringTemplates, on: self)
            .store(in: &cancellables)

        expenseRepository.$monthlyAnalytics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] analytics in
                self?.monthlyAnalytics = analytics
                self?.updateAnalyticsData()
            }
            .store(in: &cancellables)

        expenseRepository.$spendingSummary
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summary in
                self?.spendingSummary = summary
                self?.updateLimitProgress()
            }
            .store(in: &cancellables)

        // Bind to category repository
        categoryRepository.$activeCategories
            .receive(on: DispatchQueue.main)
            .assign(to: \.availableCategories, on: self)
            .store(in: &cancellables)

        categoryRepository.$categoryAnalytics
            .receive(on: DispatchQueue.main)
            .assign(to: \.categoryAnalytics, on: self)
            .store(in: &cancellables)

        // Bind to settings changes
        settingsManager.$currency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshAnalytics()
            }
            .store(in: &cancellables)

        settingsManager.$dailyLimit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLimitProgress()
            }
            .store(in: &cancellables)

        settingsManager.$monthlyLimit
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLimitProgress()
            }
            .store(in: &cancellables)

        // Form validation binding
        Publishers.CombineLatest4(
            newExpenseForm.$amount.map { $0 > 0 },
            newExpenseForm.$description.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            newExpenseForm.$categoryId.map { !$0.isEmpty },
            newExpenseForm.$subCategoryId.map { !$0.isEmpty }
        )
        .map { $0 && $1 && $2 && $3 }
        .receive(on: DispatchQueue.main)
        .assign(to: \.isFormValid, on: self)
        .store(in: &cancellables)

        // Category selection binding for subcategories
        newExpenseForm.$categoryId
            .sink { [weak self] categoryId in
                self?.loadSubCategories(for: categoryId)
            }
            .store(in: &cancellables)

        editExpenseForm.$categoryId
            .sink { [weak self] categoryId in
                self?.loadSubCategories(for: categoryId)
            }
            .store(in: &cancellables)

        // Listen for limit notifications
        NotificationCenter.default.publisher(for: .limitApproachWarning)
            .sink { [weak self] notification in
                self?.handleLimitNotification(notification)
            }
            .store(in: &cancellables)
    }

    private func loadInitialData() {
        Task {
            await loadExpenses()
            await loadRecurringTemplates()
            await refreshAnalytics()
            await loadUpcomingRecurring()
        }
    }

    // MARK: - Public Methods - Data Loading

    /// Loads expenses with current filters
    func loadExpenses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedExpenses = try await expenseRepository.getExpenses(
                startDate: isDateRangeFilterActive ? startDate : nil,
                endDate: isDateRangeFilterActive ? endDate : nil,
                categoryIds: selectedCategoryIds.isEmpty ? nil : Array(selectedCategoryIds),
                subCategoryIds: selectedSubCategoryIds.isEmpty ? nil : Array(selectedSubCategoryIds),
                status: selectedStatus,
                sortBy: sortBy,
                ascending: sortAscending
            )

            await MainActor.run {
                self.expenses = loadedExpenses
                self.applyFiltersAndSearch()
            }
        } catch {
            await handleError(error)
        }
    }

    /// Loads expenses for the currently selected date
    func loadExpensesForSelectedDate() {
        Task {
            do {
                let calendar = Calendar.current
                let dayStart = calendar.startOfDay(for: selectedDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? selectedDate

                let dayExpenses = try await expenseRepository.getExpenses(
                    startDate: dayStart,
                    endDate: dayEnd,
                    sortBy: sortBy,
                    ascending: sortAscending
                )

                await MainActor.run {
                    if calendar.isDateInToday(selectedDate) {
                        self.todayExpenses = dayExpenses
                    }
                    self.applyFiltersAndSearch()
                }
            } catch {
                await handleError(error)
            }
        }
    }

    /// Loads recurring expense templates
    func loadRecurringTemplates() async {
        do {
            let templates = try await expenseRepository.getRecurringExpenseTemplates()
            await MainActor.run {
                self.recurringTemplates = templates
            }
        } catch {
            await handleError(error)
        }
    }

    /// Loads upcoming recurring expenses
    func loadUpcomingRecurring() async {
        do {
            let calendar = Calendar.current
            let endDate = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            let upcoming = try await expenseRepository.getUpcomingRecurringExpenses(
                from: Date(),
                to: endDate
            )

            await MainActor.run {
                self.upcomingRecurringExpenses = upcoming
                self.pendingRecurringCount = upcoming.filter { $0.status == .pending }.count
            }
        } catch {
            await handleError(error)
        }
    }

    /// Refreshes all analytics data
    func refreshAnalytics() async {
        isLoadingAnalytics = true
        defer { isLoadingAnalytics = false }

        await expenseRepository.refreshAllData()
    }

    // MARK: - Public Methods - Expense Operations

    /// Creates a new expense
    func createExpense() async {
        guard isFormValid else {
            showError(L("error_invalid_form"))
            return
        }

        isCreatingExpense = true
        defer { isCreatingExpense = false }

        do {
            let expense = newExpenseForm.toExpense()
            try await expenseRepository.createExpense(expense)

            await MainActor.run {
                self.showSuccess(L("expense_created_successfully"))
                self.newExpenseForm.reset()
                self.showingAddExpense = false
            }

            await loadExpenses()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Updates an existing expense
    func updateExpense() async {
        guard let selectedExpense = selectedExpense else { return }
        guard isFormValid else {
            showError(L("error_invalid_form"))
            return
        }

        isUpdatingExpense = true
        defer { isUpdatingExpense = false }

        do {
            let updatedExpense = editExpenseForm.toExpense(id: selectedExpense.id)
            try await expenseRepository.updateExpense(updatedExpense)

            await MainActor.run {
                self.showSuccess(L("expense_updated_successfully"))
                self.editExpenseForm.reset()
                self.showingEditExpense = false
                self.selectedExpense = nil
            }

            await loadExpenses()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Deletes an expense
    func deleteExpense(_ expense: Expense) async {
        isDeletingExpense = true
        defer { isDeletingExpense = false }

        do {
            try await expenseRepository.deleteExpense(by: expense.id)

            await MainActor.run {
                self.showSuccess(L("expense_deleted_successfully"))
            }

            await loadExpenses()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Deletes multiple expenses
    func deleteSelectedExpenses() async {
        guard !selectedExpenses.isEmpty else { return }

        isDeletingExpense = true
        defer { isDeletingExpense = false }

        do {
            try await expenseRepository.deleteExpenses(by: Array(selectedExpenses))

            await MainActor.run {
                self.showSuccess(L("expenses_deleted_successfully"))
                self.selectedExpenses.removeAll()
                self.isInSelectionMode = false
            }

            await loadExpenses()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Confirms a pending recurring expense
    func confirmRecurringExpense(_ expense: Expense) async {
        do {
            try await expenseRepository.confirmRecurringExpense(expense.id)
            await loadUpcomingRecurring()
            await loadExpenses()
            showSuccess(L("recurring_expense_confirmed"))
        } catch {
            await handleError(error)
        }
    }

    /// Skips a recurring expense
    func skipRecurringExpense(_ expense: Expense) async {
        do {
            try await expenseRepository.skipRecurringExpense(expense.id)
            await loadUpcomingRecurring()
            showSuccess(L("recurring_expense_skipped"))
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Public Methods - Search and Filtering

    /// Applies current filters and search to expenses
    func applyFiltersAndSearch() {
        var filtered = expenses

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.description.localizedCaseInsensitiveContains(searchText) ||
                expense.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                String(expense.amount).contains(searchText)
            }
        }

        // Apply category filter
        if !selectedCategoryIds.isEmpty {
            filtered = filtered.filter { selectedCategoryIds.contains($0.categoryId) }
        }

        // Apply subcategory filter
        if !selectedSubCategoryIds.isEmpty {
            filtered = filtered.filter { selectedSubCategoryIds.contains($0.subCategoryId) }
        }

        // Apply status filter
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply amount range filter
        if isAmountFilterActive {
            filtered = filtered.filter { amountRange.contains($0.amount) }
        }

        // Apply date range filter
        if isDateRangeFilterActive {
            filtered = filtered.filter { expense in
                expense.date >= startDate && expense.date <= endDate
            }
        }

        // Apply sorting
        filtered = sortExpenses(filtered)

        filteredExpenses = filtered
    }

    /// Clears all filters and search
    func clearFilters() {
        searchText = ""
        selectedCategoryIds.removeAll()
        selectedSubCategoryIds.removeAll()
        selectedStatus = nil
        isDateRangeFilterActive = false
        isAmountFilterActive = false
        sortBy = .date
        sortAscending = false
    }

    /// Searches expenses with the given text
    func searchExpenses(with text: String) async {
        do {
            let results = try await expenseRepository.searchExpenses(text)
            await MainActor.run {
                self.expenses = results
                self.applyFiltersAndSearch()
            }
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Public Methods - Form Management

    /// Prepares form for creating new expense
    func prepareNewExpenseForm() {
        newExpenseForm.reset()
        newExpenseForm.date = selectedDate
        if !settingsManager.defaultCategoryId.isEmpty {
            newExpenseForm.categoryId = settingsManager.defaultCategoryId
        }
        formErrors.removeAll()
    }

    /// Prepares form for editing expense
    func prepareEditExpenseForm(for expense: Expense) {
        selectedExpense = expense
        editExpenseForm.populateFrom(expense)
        formErrors.removeAll()
    }

    /// Validates form and updates error state
    func validateForm() {
        formErrors.removeAll()

        let form = showingAddExpense ? newExpenseForm : editExpenseForm

        if form.amount <= 0 {
            formErrors["amount"] = L("error_invalid_amount")
        }

        if form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formErrors["description"] = L("error_missing_description")
        }

        if form.categoryId.isEmpty {
            formErrors["category"] = L("error_missing_category")
        }

        if form.subCategoryId.isEmpty {
            formErrors["subCategory"] = L("error_missing_subcategory")
        }

        if form.recurrenceType != .none {
            if let endDate = form.recurrenceEndDate, endDate <= form.date {
                formErrors["recurrenceEndDate"] = L("error_invalid_recurrence_end_date")
            }

            if form.recurrenceType == .custom && form.customRecurrenceInterval <= 0 {
                formErrors["customRecurrence"] = L("error_invalid_custom_recurrence")
            }
        }
    }

    // MARK: - Public Methods - Selection and Bulk Operations

    /// Toggles selection of an expense
    func toggleExpenseSelection(_ expenseId: String) {
        if selectedExpenses.contains(expenseId) {
            selectedExpenses.remove(expenseId)
        } else {
            selectedExpenses.insert(expenseId)
        }
    }

    /// Selects all filtered expenses
    func selectAllExpenses() {
        selectedExpenses = Set(filteredExpenses.map { $0.id })
    }

    /// Deselects all expenses
    func deselectAllExpenses() {
        selectedExpenses.removeAll()
    }

    /// Enters selection mode
    func enterSelectionMode() {
        isInSelectionMode = true
        selectedExpenses.removeAll()
    }

    /// Exits selection mode
    func exitSelectionMode() {
        isInSelectionMode = false
        selectedExpenses.removeAll()
    }

    // MARK: - Public Methods - Quick Actions

    /// Duplicates an expense
    func duplicateExpense(_ expense: Expense) {
        let duplicatedExpense = expense.duplicated()
        newExpenseForm.populateFrom(duplicatedExpense)
        showingAddExpense = true
    }

    /// Creates a recurring template from an expense
    func createRecurringTemplate(from expense: Expense) {
        let templateExpense = expense.asRecurringTemplate()
        newExpenseForm.populateFrom(templateExpense)
        newExpenseForm.recurrenceType = .monthly // Default
        showingAddExpense = true
    }

    /// Quick add expense with minimal form
    func quickAddExpense(amount: Double, description: String, categoryId: String? = nil) async {
        let expense = Expense(
            amount: amount,
            currency: settingsManager.currency,
            categoryId: categoryId ?? settingsManager.defaultCategoryId,
            subCategoryId: "", // Will need to be set
            description: description,
            date: Date(),
            status: settingsManager.defaultExpenseStatus
        )

        do {
            try await expenseRepository.createExpense(expense)
            showSuccess(L("expense_added_quickly"))
            await loadExpenses()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Private Methods

    private func sortExpenses(_ expenses: [Expense]) -> [Expense] {
        return expenses.sorted { lhs, rhs in
            let result: Bool
            switch sortBy {
            case .date:
                result = lhs.date < rhs.date
            case .amount:
                result = lhs.amount < rhs.amount
            case .description:
                result = lhs.description < rhs.description
            case .category:
                result = lhs.categoryId < rhs.categoryId
            case .createdAt:
                result = lhs.createdAt < rhs.createdAt
            }
            return sortAscending ? result : !result
        }
    }

    private func loadSubCategories(for categoryId: String) {
        guard !categoryId.isEmpty else {
            availableSubCategories = []
            return
        }

        Task {
            do {
                let subCategories = try await categoryRepository.getSubCategories(for: categoryId)
                await MainActor.run {
                    self.availableSubCategories = subCategories
                }
            } catch {
                print("Failed to load subcategories: \(error)")
            }
        }
    }

    private func updateAnalyticsData() {
        guard let analytics = monthlyAnalytics else { return }

        dailyTotals = analytics.dailyTotals
        categoryBreakdown = analytics.categoryTotals

        // Update trends (simplified calculation)
        weeklyTrend = calculateWeeklyTrend()
        monthlyTrend = calculateMonthlyTrend()
    }

    private func updateLimitProgress() {
        guard let summary = spendingSummary else { return }

        dailyLimitProgress = summary.dailyLimitUsagePercentage / 100
        monthlyLimitProgress = summary.monthlyLimitUsagePercentage / 100
        yearlyLimitProgress = summary.yearlyLimitUsagePercentage / 100

        isDailyLimitExceeded = summary.isDailyLimitExceeded
        isMonthlyLimitExceeded = summary.isMonthlyLimitExceeded
        isYearlyLimitExceeded = summary.isYearlyLimitExceeded
    }

    private func calculateWeeklyTrend() -> [Double] {
        // Calculate last 4 weeks spending
        let calendar = Calendar.current
        let now = Date()
        var weeklyAmounts: [Double] = []

        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now

            let weekExpenses = thisMonthExpenses.filter { expense in
                expense.date >= weekStart && expense.date < weekEnd
            }

            weeklyAmounts.append(weekExpenses.reduce(0) { $0 + $1.amount })
        }

        return weeklyAmounts.reversed()
    }

    private func calculateMonthlyTrend() -> [Double] {
        // This would need historical data - simplified for now
        return [1000, 1200, 950, 1100, 1300, 1150] // Placeholder
    }

    private func handleLimitNotification(_ notification: Notification) {
        guard let userInfo = notification.object as? [String: Any],
              let type = userInfo["type"] as? LimitType,
              let percentage = userInfo["percentage"] as? Double else { return }

        let limitNotification = LimitNotification(
            type: type,
            percentage: percentage,
            timestamp: Date()
        )

        limitNotifications.append(limitNotification)

        // Auto-remove after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.limitNotifications.removeAll { $0.id == limitNotification.id }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsManager.currency
        if !settingsManager.showDecimalPlaces {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(settingsManager.currency)"
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccessAlert = true
    }

    @MainActor
    private func handleError(_ error: Error) async {
        let message = error.localizedDescription
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Supporting Types

/// Form state for expense creation and editing
class ExpenseFormState: ObservableObject {
    @Published var amount: Double = 0.0
    @Published var currency: String = "TRY"
    @Published var categoryId: String = ""
    @Published var subCategoryId: String = ""
    @Published var description: String = ""
    @Published var notes: String = ""
    @Published var date: Date = Date()
    @Published var location: String = ""
    @Published var tags: [String] = []
    @Published var recurrenceType: RecurrenceType = .none
    @Published var recurrenceEndDate: Date? = nil
    @Published var customRecurrenceInterval: Int = 1
    @Published var status: ExpenseStatus = .confirmed

    func reset() {
        amount = 0.0
        currency = SettingsManager.shared.currency
        categoryId = ""
        subCategoryId = ""
        description = ""
        notes = ""
        date = Date()
        location = ""
        tags = []
        recurrenceType = .none
        recurrenceEndDate = nil
        customRecurrenceInterval = 1
        status = SettingsManager.shared.defaultExpenseStatus
    }

    func populateFrom(_ expense: Expense) {
        amount = expense.amount
        currency = expense.currency
        categoryId = expense.categoryId
        subCategoryId = expense.subCategoryId
        description = expense.description
        notes = expense.notes ?? ""
        date = expense.date
        location = expense.location ?? ""
        tags = expense.tags
        recurrenceType = expense.recurrenceType
        recurrenceEndDate = expense.recurrenceEndDate
        customRecurrenceInterval = expense.customRecurrenceInterval
        status = expense.status
    }

    func toExpense(id: String = UUID().uuidString) -> Expense {
        return Expense(
            id: id,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            description: description,
            date: date,
            dailyLimitAtCreation: SettingsManager.shared.dailyLimit,
            monthlyLimitAtCreation: SettingsManager.shared.monthlyLimit,
            yearlyLimitAtCreation: SettingsManager.shared.yearlyLimit,
            recurrenceType: recurrenceType,
            recurrenceEndDate: recurrenceEndDate,
            customRecurrenceInterval: customRecurrenceInterval,
            status: status,
            tags: tags,
            notes: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            isRecurring: recurrenceType != .none,
            parentExpenseId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Budget progress information
struct BudgetProgress {
    let categoryId: String
    let categoryName: String
    let budgetAmount: Double
    let spentAmount: Double
    let remainingAmount: Double
    let progressPercentage: Double
    let isOverBudget: Bool

    var formattedBudgetAmount: String {
        formatCurrency(budgetAmount)
    }

    var formattedSpentAmount: String {
        formatCurrency(spentAmount)
    }

    var formattedRemainingAmount: String {
        formatCurrency(remainingAmount)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = SettingsManager.shared.currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}

/// Limit notification information
struct LimitNotification: Identifiable {
    let id = UUID()
    let type: LimitType
    let percentage: Double
    let timestamp: Date

    var title: String {
        switch type {
        case .daily:
            return L("daily_limit_warning")
        case .monthly:
            return L("monthly_limit_warning")
        case .yearly:
            return L("yearly_limit_warning")
        }
    }

    var message: String {
        switch type {
        case .daily:
            return L("daily_limit_warning_message", percentage)
        case .monthly:
            return L("monthly_limit_warning_message", percentage)
        case .yearly:
            return L("yearly_limit_warning_message", percentage)
        }
    }
}

/// Expense sort fields
enum ExpenseSortField: String, CaseIterable {
    case date = "date"
    case amount = "amount"
    case description = "description"
    case category = "category"
    case createdAt = "createdAt"

    var displayName: String {
        switch self {
        case .date:
            return L("sort_by_date")
        case .amount:
            return L("sort_by_amount")
        case .description:
            return L("sort_by_description")
        case .category:
            return L("sort_by_category")
        case .createdAt:
            return L("sort_by_created")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let limitApproachWarning = Notification.Name("limitApproachWarning")
    static let currencyChanged = Notification.Name("currencyChanged")
    static let limitsChanged = Notification.Name("limitsChanged")
    static let themeChanged = Notification.Name("themeChanged")
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Expense Extensions

extension Expense {
    func duplicated() -> Expense {
        return Expense(
            amount: self.amount,
            currency: self.currency,
            categoryId: self.categoryId,
            subCategoryId: self.subCategoryId,
            description: "\(self.description) (\(L("copy")))",
            date: Date(),
            status: self.status,
            tags: self.tags,
            notes: self.notes,
            location: self.location
        )
    }

    func asRecurringTemplate() -> Expense {
        return Expense(
            amount: self.amount,
            currency: self.currency,
            categoryId: self.categoryId,
            subCategoryId: self.subCategoryId,
            description: self.description,
            date: Date(),
            status: .confirmed,
            tags: self.tags,
            notes: self.notes,
            location: self.location,
            isRecurring: true
        )
    }
}

// MARK: - Array Extensions

extension Array where Element == Expense {
    var totalAmount: Double {
        reduce(0) { $0 + $1.amount }
    }
}

// MARK: - Localization Helper

func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, comment: "")
    return String(format: format, arguments: args)
}

// MARK: - Preview Helper

#if DEBUG
extension ExpenseViewModel {
    static let preview: ExpenseViewModel = {
        return ExpenseViewModel(
            expenseRepository: ExpenseRepository.preview,
            categoryRepository: CategoryRepository.preview,
            settingsManager: SettingsManager.preview
        )
    }()
}
#endif