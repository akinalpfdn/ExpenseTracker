//
//  ExpenseRepository.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive expense repository with business logic and recurring expense management
/// Provides high-level expense operations, analytics, and recurring expense generation
/// Uses ExpenseDataAccess for Core Data operations and adds business logic layer
@MainActor
class ExpenseRepository: ObservableObject {

    // MARK: - Properties

    private let expenseDataAccess: ExpenseDataAccess
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    /// Published property for recent expenses
    @Published var recentExpenses: [Expense] = []

    /// Published property for today's expenses
    @Published var todayExpenses: [Expense] = []

    /// Published property for this month's expenses
    @Published var thisMonthExpenses: [Expense] = []

    /// Published property for recurring expense templates
    @Published var recurringTemplates: [Expense] = []

    /// Published property for expense analytics
    @Published var monthlyAnalytics: ExpenseAnalytics?

    /// Published property for spending summary
    @Published var spendingSummary: SpendingSummary?

    // MARK: - Initialization

    init(
        expenseDataAccess: ExpenseDataAccess = ExpenseDataAccess(),
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.expenseDataAccess = expenseDataAccess
        self.settingsManager = settingsManager
        setupBindings()
        loadInitialData()
    }

    // MARK: - Private Setup Methods

    private func setupBindings() {
        // Listen for data changes from the data access layer
        expenseDataAccess.$recentExpenses
            .sink { [weak self] expenses in
                self?.recentExpenses = expenses
                self?.updateDerivedData()
            }
            .store(in: &cancellables)

        // Listen for settings changes that might affect expense display
        settingsManager.$currency
            .sink { [weak self] _ in
                self?.refreshAnalytics()
            }
            .store(in: &cancellables)
    }

    private func loadInitialData() {
        Task {
            await refreshAllData()
        }
    }

    // MARK: - Public Methods - CRUD Operations

    /// Creates a new expense with business logic validation
    /// - Parameter expense: The expense to create
    /// - Throws: ExpenseRepositoryError if validation fails or creation fails
    func createExpense(_ expense: Expense) async throws {
        // Validate expense before creation
        try validateExpense(expense)

        // Check spending limits
        try await checkSpendingLimits(for: expense)

        // Apply current settings
        let enhancedExpense = enhanceExpenseWithSettings(expense)

        // Create the expense
        try await expenseDataAccess.createExpense(enhancedExpense)

        // Generate recurring expenses if needed
        if enhancedExpense.recurrenceType != .none {
            try await generateRecurringExpenses(from: enhancedExpense)
        }

        // Update analytics
        await refreshAnalytics()

        // Trigger haptic feedback
        settingsManager.triggerHapticFeedback(.light)

        // Send notification if limits are approached
        await checkAndNotifyLimitApproach(after: enhancedExpense)
    }

    /// Updates an existing expense
    /// - Parameter expense: The updated expense
    /// - Throws: ExpenseRepositoryError if validation fails or update fails
    func updateExpense(_ expense: Expense) async throws {
        try validateExpense(expense)

        // Check if recurrence changed and handle accordingly
        let existingExpense = try await expenseDataAccess.getExpense(by: expense.id)

        try await expenseDataAccess.updateExpense(expense)

        // Handle recurrence changes
        if let existing = existingExpense,
           existing.recurrenceType != expense.recurrenceType {
            try await handleRecurrenceChange(original: existing, updated: expense)
        }

        await refreshAnalytics()
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Deletes an expense and related recurring instances
    /// - Parameter id: The expense ID to delete
    /// - Throws: ExpenseRepositoryError if deletion fails
    func deleteExpense(by id: String) async throws {
        try await expenseDataAccess.deleteExpense(by: id)
        await refreshAnalytics()
        settingsManager.triggerHapticFeedback(.medium)
    }

    /// Bulk deletes multiple expenses
    /// - Parameter ids: Array of expense IDs to delete
    /// - Throws: ExpenseRepositoryError if deletion fails
    func deleteExpenses(by ids: [String]) async throws {
        try await expenseDataAccess.deleteExpenses(by: ids)
        await refreshAnalytics()
        settingsManager.triggerHapticFeedback(.heavy)
    }

    // MARK: - Public Methods - Retrieval and Search

    /// Gets expenses with advanced filtering options
    /// - Parameters:
    ///   - startDate: Start date filter
    ///   - endDate: End date filter
    ///   - categoryIds: Category filters
    ///   - subCategoryIds: SubCategory filters
    ///   - status: Status filter
    ///   - sortBy: Sort field
    ///   - ascending: Sort direction
    ///   - limit: Maximum results
    /// - Returns: Array of filtered expenses
    func getExpenses(
        startDate: Date? = nil,
        endDate: Date? = nil,
        categoryIds: [String]? = nil,
        subCategoryIds: [String]? = nil,
        status: ExpenseStatus? = nil,
        sortBy: ExpenseSortField = .date,
        ascending: Bool = false,
        limit: Int? = nil
    ) async throws -> [Expense] {
        return try await expenseDataAccess.getExpenses(
            startDate: startDate,
            endDate: endDate,
            categoryIds: categoryIds,
            subCategoryIds: subCategoryIds,
            status: status,
            sortBy: sortBy,
            ascending: ascending,
            limit: limit
        )
    }

    /// Searches expenses with intelligent matching
    /// - Parameter searchText: Search query
    /// - Returns: Array of matching expenses
    func searchExpenses(_ searchText: String) async throws -> [Expense] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        // First try direct description/notes search
        var results = try await expenseDataAccess.searchExpenses(by: searchText)

        // If auto-categorization is enabled, also search by amount patterns
        if settingsManager.autoCategorizeEnabled {
            results = try await enhanceSearchWithSmartMatching(results, query: searchText)
        }

        return results
    }

    /// Gets expenses by tags with smart tag matching
    /// - Parameter tags: Array of tags to search for
    /// - Returns: Array of expenses containing any of the tags
    func getExpensesByTags(_ tags: [String]) async throws -> [Expense] {
        return try await expenseDataAccess.getExpensesByTags(tags)
    }

    // MARK: - Public Methods - Recurring Expenses

    /// Gets all recurring expense templates
    /// - Returns: Array of recurring expense templates
    func getRecurringExpenseTemplates() async throws -> [Expense] {
        let templates = try await expenseDataAccess.getRecurringExpenseTemplates()
        await MainActor.run {
            self.recurringTemplates = templates
        }
        return templates
    }

    /// Gets upcoming recurring expenses for a date range
    /// - Parameters:
    ///   - startDate: Start date for the range
    ///   - endDate: End date for the range
    /// - Returns: Array of upcoming recurring expenses
    func getUpcomingRecurringExpenses(from startDate: Date, to endDate: Date) async throws -> [Expense] {
        let templates = try await getRecurringExpenseTemplates()
        var upcomingExpenses: [Expense] = []

        for template in templates {
            let occurrences = template.recurrenceType.occurrences(
                from: startDate,
                to: endDate,
                baseDate: template.date
            )

            for occurrence in occurrences {
                // Check if this occurrence already exists
                let existingExpenses = try await getExpenses(
                    startDate: Calendar.current.startOfDay(for: occurrence),
                    endDate: Calendar.current.date(byAdding: .day, value: 1, to: occurrence) ?? occurrence
                )

                let alreadyExists = existingExpenses.contains { expense in
                    expense.parentExpenseId == template.id &&
                    Calendar.current.isDate(expense.date, inSameDayAs: occurrence)
                }

                if !alreadyExists {
                    let recurringExpense = createRecurringExpenseInstance(from: template, date: occurrence)
                    upcomingExpenses.append(recurringExpense)
                }
            }
        }

        return upcomingExpenses.sorted { $0.date < $1.date }
    }

    /// Generates recurring expenses for all templates up to a future date
    /// - Parameter endDate: End date for generation (default: 3 months from now)
    /// - Returns: Number of expenses generated
    @discardableResult
    func generateUpcomingRecurringExpenses(until endDate: Date? = nil) async throws -> Int {
        let finalEndDate = endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let upcomingExpenses = try await getUpcomingRecurringExpenses(from: Date(), to: finalEndDate)

        var generatedCount = 0

        for expense in upcomingExpenses {
            do {
                try await expenseDataAccess.createExpense(expense)
                generatedCount += 1
            } catch {
                // Log error but continue with other expenses
                print("Failed to generate recurring expense: \(error)")
            }
        }

        if generatedCount > 0 {
            await refreshAnalytics()
        }

        return generatedCount
    }

    /// Confirms a pending recurring expense
    /// - Parameter expenseId: ID of the expense to confirm
    /// - Throws: ExpenseRepositoryError if expense not found or already confirmed
    func confirmRecurringExpense(_ expenseId: String) async throws {
        guard let expense = try await expenseDataAccess.getExpense(by: expenseId) else {
            throw ExpenseRepositoryError.expenseNotFound
        }

        guard expense.status == .pending else {
            throw ExpenseRepositoryError.expenseNotPending
        }

        let confirmedExpense = expense.withStatus(.confirmed)
        try await expenseDataAccess.updateExpense(confirmedExpense)
        await refreshAnalytics()
    }

    /// Skips a recurring expense instance
    /// - Parameter expenseId: ID of the expense to skip
    /// - Throws: ExpenseRepositoryError if expense not found
    func skipRecurringExpense(_ expenseId: String) async throws {
        guard let expense = try await expenseDataAccess.getExpense(by: expenseId) else {
            throw ExpenseRepositoryError.expenseNotFound
        }

        let skippedExpense = expense.withStatus(.cancelled)
        try await expenseDataAccess.updateExpense(skippedExpense)
        await refreshAnalytics()
    }

    // MARK: - Public Methods - Analytics

    /// Gets comprehensive expense analytics for a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: ExpenseAnalytics containing detailed analysis
    func getExpenseAnalytics(startDate: Date, endDate: Date) async throws -> ExpenseAnalytics {
        let expenses = try await getExpenses(
            startDate: startDate,
            endDate: endDate,
            status: .confirmed
        )

        let categoryTotals = try await expenseDataAccess.getExpensesByCategory(
            startDate: startDate,
            endDate: endDate
        )

        let subCategoryTotals = try await expenseDataAccess.getExpensesBySubCategory(
            startDate: startDate,
            endDate: endDate
        )

        let dailyTotals = try await expenseDataAccess.getDailyExpenseTotals(
            startDate: startDate,
            endDate: endDate
        )

        let statistics = try await expenseDataAccess.getExpenseStatistics(
            startDate: startDate,
            endDate: endDate
        )

        return ExpenseAnalytics(
            startDate: startDate,
            endDate: endDate,
            totalAmount: statistics["totalAmount"] as? Double ?? 0,
            averageAmount: statistics["averageAmount"] as? Double ?? 0,
            medianAmount: statistics["medianAmount"] as? Double ?? 0,
            maxAmount: statistics["maxAmount"] as? Double ?? 0,
            minAmount: statistics["minAmount"] as? Double ?? 0,
            expenseCount: statistics["expenseCount"] as? Int ?? 0,
            categoryTotals: categoryTotals,
            subCategoryTotals: subCategoryTotals,
            dailyTotals: dailyTotals,
            currency: settingsManager.currency
        )
    }

    /// Gets spending summary for current period
    /// - Returns: SpendingSummary with current period analysis
    func getCurrentSpendingSummary() async throws -> SpendingSummary {
        let now = Date()
        let calendar = Calendar.current

        // Today
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? now

        // This month
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now

        // This year
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? now

        let todayAnalytics = try await getExpenseAnalytics(startDate: todayStart, endDate: todayEnd)
        let monthAnalytics = try await getExpenseAnalytics(startDate: monthStart, endDate: monthEnd)
        let yearAnalytics = try await getExpenseAnalytics(startDate: yearStart, endDate: yearEnd)

        return SpendingSummary(
            today: todayAnalytics.totalAmount,
            thisMonth: monthAnalytics.totalAmount,
            thisYear: yearAnalytics.totalAmount,
            dailyLimit: settingsManager.dailyLimit,
            monthlyLimit: settingsManager.monthlyLimit,
            yearlyLimit: settingsManager.yearlyLimit,
            currency: settingsManager.currency
        )
    }

    /// Gets spending trends analysis
    /// - Parameter months: Number of months to analyze
    /// - Returns: SpendingTrends with trend analysis
    func getSpendingTrends(months: Int = 6) async throws -> SpendingTrends {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -months, to: endDate) ?? endDate

        var monthlyTotals: [String: Double] = [:]
        var monthlyAverages: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let calendar = Calendar.current
        var currentDate = startDate

        while currentDate < endDate {
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            let monthKey = formatter.string(from: currentDate)

            let monthAnalytics = try await getExpenseAnalytics(startDate: currentDate, endDate: monthEnd)
            monthlyTotals[monthKey] = monthAnalytics.totalAmount

            let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)?.count ?? 30
            monthlyAverages[monthKey] = monthAnalytics.totalAmount / Double(daysInMonth)

            currentDate = monthEnd
        }

        return SpendingTrends(
            monthlyTotals: monthlyTotals,
            monthlyAverages: monthlyAverages,
            currency: settingsManager.currency
        )
    }

    // MARK: - Public Methods - Data Management

    /// Refreshes all cached data
    func refreshAllData() async {
        await refreshAnalytics()
        try? await getRecurringExpenseTemplates()
        updateDerivedData()
    }

    /// Clears all cached data
    func clearCache() {
        recentExpenses = []
        todayExpenses = []
        thisMonthExpenses = []
        recurringTemplates = []
        monthlyAnalytics = nil
        spendingSummary = nil
    }

    // MARK: - Private Methods - Business Logic

    private func validateExpense(_ expense: Expense) throws {
        guard expense.amount > 0 else {
            throw ExpenseRepositoryError.invalidAmount
        }

        guard !expense.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExpenseRepositoryError.missingDescription
        }

        guard !expense.categoryId.isEmpty else {
            throw ExpenseRepositoryError.missingCategory
        }

        guard !expense.subCategoryId.isEmpty else {
            throw ExpenseRepositoryError.missingSubCategory
        }

        // Validate recurrence settings
        if expense.recurrenceType != .none {
            if let endDate = expense.recurrenceEndDate,
               endDate <= expense.date {
                throw ExpenseRepositoryError.invalidRecurrenceEndDate
            }

            if expense.recurrenceType == .custom && expense.customRecurrenceInterval <= 0 {
                throw ExpenseRepositoryError.invalidCustomRecurrence
            }
        }
    }

    private func enhanceExpenseWithSettings(_ expense: Expense) -> Expense {
        return expense.updated(with: [
            "currency": settingsManager.currency,
            "dailyLimitAtCreation": settingsManager.dailyLimit,
            "monthlyLimitAtCreation": settingsManager.monthlyLimit,
            "yearlyLimitAtCreation": settingsManager.yearlyLimit,
            "status": settingsManager.defaultExpenseStatus
        ])
    }

    private func checkSpendingLimits(for expense: Expense) async throws {
        guard settingsManager.hasAnyLimitConfigured() else { return }

        let calendar = Calendar.current
        let expenseDate = expense.date

        // Check daily limit
        if settingsManager.dailyLimit > 0 {
            let dayStart = calendar.startOfDay(for: expenseDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? expenseDate

            let dayExpenses = try await getExpenses(
                startDate: dayStart,
                endDate: dayEnd,
                status: .confirmed
            )

            let dayTotal = dayExpenses.totalAmount + expense.amount
            if dayTotal > settingsManager.dailyLimit {
                throw ExpenseRepositoryError.dailyLimitExceeded(
                    current: dayTotal,
                    limit: settingsManager.dailyLimit
                )
            }
        }

        // Check monthly limit
        if settingsManager.monthlyLimit > 0 {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: expenseDate)) ?? expenseDate
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? expenseDate

            let monthExpenses = try await getExpenses(
                startDate: monthStart,
                endDate: monthEnd,
                status: .confirmed
            )

            let monthTotal = monthExpenses.totalAmount + expense.amount
            if monthTotal > settingsManager.monthlyLimit {
                throw ExpenseRepositoryError.monthlyLimitExceeded(
                    current: monthTotal,
                    limit: settingsManager.monthlyLimit
                )
            }
        }

        // Check yearly limit
        if settingsManager.yearlyLimit > 0 {
            let yearStart = calendar.date(from: calendar.dateComponents([.year], from: expenseDate)) ?? expenseDate
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? expenseDate

            let yearExpenses = try await getExpenses(
                startDate: yearStart,
                endDate: yearEnd,
                status: .confirmed
            )

            let yearTotal = yearExpenses.totalAmount + expense.amount
            if yearTotal > settingsManager.yearlyLimit {
                throw ExpenseRepositoryError.yearlyLimitExceeded(
                    current: yearTotal,
                    limit: settingsManager.yearlyLimit
                )
            }
        }
    }

    private func generateRecurringExpenses(from template: Expense) async throws {
        let recurringExpenses = template.generateRecurringExpenses()

        for recurringExpense in recurringExpenses {
            try await expenseDataAccess.createExpense(recurringExpense)
        }
    }

    private func handleRecurrenceChange(original: Expense, updated: Expense) async throws {
        // If recurrence was removed, delete future instances
        if original.recurrenceType != .none && updated.recurrenceType == .none {
            let futureInstances = try await expenseDataAccess.getRecurringExpenseInstances(for: original.id)
            let futureIds = futureInstances
                .filter { $0.date > Date() && $0.status == .pending }
                .map { $0.id }

            if !futureIds.isEmpty {
                try await expenseDataAccess.deleteExpenses(by: futureIds)
            }
        }
        // If recurrence was added or changed, regenerate instances
        else if updated.recurrenceType != .none {
            // Delete existing future instances
            let existingInstances = try await expenseDataAccess.getRecurringExpenseInstances(for: original.id)
            let futureIds = existingInstances
                .filter { $0.date > Date() && $0.status == .pending }
                .map { $0.id }

            if !futureIds.isEmpty {
                try await expenseDataAccess.deleteExpenses(by: futureIds)
            }

            // Generate new instances
            try await generateRecurringExpenses(from: updated)
        }
    }

    private func createRecurringExpenseInstance(from template: Expense, date: Date) -> Expense {
        return Expense(
            amount: template.amount,
            currency: template.currency,
            categoryId: template.categoryId,
            subCategoryId: template.subCategoryId,
            description: "\(template.description) (\(L("recurring")))",
            date: date,
            dailyLimitAtCreation: template.dailyLimitAtCreation,
            monthlyLimitAtCreation: template.monthlyLimitAtCreation,
            yearlyLimitAtCreation: template.yearlyLimitAtCreation,
            recurrenceType: template.recurrenceType,
            recurrenceEndDate: template.recurrenceEndDate,
            customRecurrenceInterval: template.customRecurrenceInterval,
            status: .pending,
            tags: template.tags,
            notes: template.notes,
            location: template.location,
            isRecurring: true,
            parentExpenseId: template.id
        )
    }

    private func enhanceSearchWithSmartMatching(_ results: [Expense], query: String) async throws -> [Expense] {
        // This could be enhanced with ML-based matching in the future
        // For now, implement basic smart matching

        // Try to parse query as amount
        if let queryAmount = Double(query) {
            let amountMatches = try await getExpenses()
                .filter { abs($0.amount - queryAmount) < 0.01 }

            // Merge with existing results
            let combinedResults = Set(results + amountMatches)
            return Array(combinedResults).sorted { $0.date > $1.date }
        }

        return results
    }

    private func checkAndNotifyLimitApproach(after expense: Expense) async {
        guard settingsManager.shouldShowLimitNotifications() else { return }

        // Check if we're approaching limits (80% threshold)
        let currentSummary = try? await getCurrentSpendingSummary()

        if let summary = currentSummary {
            if summary.dailyLimitUsagePercentage >= 80 {
                sendLimitApproachNotification(type: .daily, percentage: summary.dailyLimitUsagePercentage)
            }

            if summary.monthlyLimitUsagePercentage >= 80 {
                sendLimitApproachNotification(type: .monthly, percentage: summary.monthlyLimitUsagePercentage)
            }

            if summary.yearlyLimitUsagePercentage >= 80 {
                sendLimitApproachNotification(type: .yearly, percentage: summary.yearlyLimitUsagePercentage)
            }
        }
    }

    private func sendLimitApproachNotification(type: LimitType, percentage: Double) {
        // This would integrate with the notification system
        // For now, just post a notification
        let notification = Notification.Name("limitApproachWarning")
        NotificationCenter.default.post(
            name: notification,
            object: ["type": type, "percentage": percentage]
        )
    }

    private func refreshAnalytics() async {
        do {
            let now = Date()
            let calendar = Calendar.current
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now

            let analytics = try await getExpenseAnalytics(startDate: monthStart, endDate: monthEnd)
            let summary = try await getCurrentSpendingSummary()

            await MainActor.run {
                self.monthlyAnalytics = analytics
                self.spendingSummary = summary
            }
        } catch {
            print("Failed to refresh analytics: \(error)")
        }
    }

    private func updateDerivedData() {
        let calendar = Calendar.current
        let now = Date()

        // Update today's expenses
        todayExpenses = recentExpenses.filter { calendar.isDateInToday($0.date) }

        // Update this month's expenses
        thisMonthExpenses = recentExpenses.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
    }
}

// MARK: - Supporting Types

/// Expense repository specific errors
enum ExpenseRepositoryError: LocalizedError {
    case invalidAmount
    case missingDescription
    case missingCategory
    case missingSubCategory
    case invalidRecurrenceEndDate
    case invalidCustomRecurrence
    case expenseNotFound
    case expenseNotPending
    case dailyLimitExceeded(current: Double, limit: Double)
    case monthlyLimitExceeded(current: Double, limit: Double)
    case yearlyLimitExceeded(current: Double, limit: Double)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return L("error_invalid_amount")
        case .missingDescription:
            return L("error_missing_description")
        case .missingCategory:
            return L("error_missing_category")
        case .missingSubCategory:
            return L("error_missing_subcategory")
        case .invalidRecurrenceEndDate:
            return L("error_invalid_recurrence_end_date")
        case .invalidCustomRecurrence:
            return L("error_invalid_custom_recurrence")
        case .expenseNotFound:
            return L("error_expense_not_found")
        case .expenseNotPending:
            return L("error_expense_not_pending")
        case .dailyLimitExceeded(let current, let limit):
            return L("error_daily_limit_exceeded", current, limit)
        case .monthlyLimitExceeded(let current, let limit):
            return L("error_monthly_limit_exceeded", current, limit)
        case .yearlyLimitExceeded(let current, let limit):
            return L("error_yearly_limit_exceeded", current, limit)
        }
    }
}

/// Comprehensive expense analytics
struct ExpenseAnalytics {
    let startDate: Date
    let endDate: Date
    let totalAmount: Double
    let averageAmount: Double
    let medianAmount: Double
    let maxAmount: Double
    let minAmount: Double
    let expenseCount: Int
    let categoryTotals: [String: Double]
    let subCategoryTotals: [String: Double]
    let dailyTotals: [String: Double]
    let currency: String

    var formattedTotalAmount: String {
        return formatCurrency(totalAmount)
    }

    var formattedAverageAmount: String {
        return formatCurrency(averageAmount)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
}

/// Current spending summary
struct SpendingSummary {
    let today: Double
    let thisMonth: Double
    let thisYear: Double
    let dailyLimit: Double
    let monthlyLimit: Double
    let yearlyLimit: Double
    let currency: String

    var dailyLimitUsagePercentage: Double {
        guard dailyLimit > 0 else { return 0 }
        return min((today / dailyLimit) * 100, 100)
    }

    var monthlyLimitUsagePercentage: Double {
        guard monthlyLimit > 0 else { return 0 }
        return min((thisMonth / monthlyLimit) * 100, 100)
    }

    var yearlyLimitUsagePercentage: Double {
        guard yearlyLimit > 0 else { return 0 }
        return min((thisYear / yearlyLimit) * 100, 100)
    }

    var isDailyLimitExceeded: Bool {
        return dailyLimit > 0 && today > dailyLimit
    }

    var isMonthlyLimitExceeded: Bool {
        return monthlyLimit > 0 && thisMonth > monthlyLimit
    }

    var isYearlyLimitExceeded: Bool {
        return yearlyLimit > 0 && thisYear > yearlyLimit
    }
}

/// Spending trends analysis
struct SpendingTrends {
    let monthlyTotals: [String: Double]
    let monthlyAverages: [String: Double]
    let currency: String

    var sortedMonths: [String] {
        return monthlyTotals.keys.sorted()
    }

    var trend: TrendDirection {
        let months = sortedMonths
        guard months.count >= 2 else { return .stable }

        let recent = monthlyTotals[months.last!] ?? 0
        let previous = monthlyTotals[months[months.count - 2]] ?? 0

        if recent > previous * 1.1 { return .increasing }
        if recent < previous * 0.9 { return .decreasing }
        return .stable
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

enum LimitType {
    case daily
    case monthly
    case yearly
}

// MARK: - Preview Helper

#if DEBUG
extension ExpenseRepository {
    static let preview: ExpenseRepository = {
        return ExpenseRepository(
            expenseDataAccess: ExpenseDataAccess.preview,
            settingsManager: SettingsManager.preview
        )
    }()
}
#endif