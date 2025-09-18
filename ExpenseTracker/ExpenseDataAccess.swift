//
//  ExpenseDataAccess.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData
import Combine

/// Data access layer for Expense entities
/// Provides comprehensive CRUD operations, queries, analytics, and business logic
@MainActor
class ExpenseDataAccess: ObservableObject {

    // MARK: - Properties

    private let coreDataStack: CoreDataStack

    /// Published property for expenses to notify SwiftUI views
    @Published var expenses: [Expense] = []

    /// Published property for recent expenses
    @Published var recentExpenses: [Expense] = []

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadRecentExpenses()
    }

    // MARK: - Expense CRUD Operations

    /// Creates a new expense
    /// - Parameter expense: The expense to create
    /// - Throws: Core Data error if creation fails
    func createExpense(_ expense: Expense) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let cdExpense = CDExpense.from(expense, context: context)

            // Set up relationships
            self.setupExpenseRelationships(cdExpense, expense: expense, context: context)

            // Handle recurring expenses
            if expense.recurrenceType != .none {
                let recurringExpenses = expense.generateRecurringExpenses()
                for recurringExpense in recurringExpenses {
                    let cdRecurringExpense = CDExpense.from(recurringExpense, context: context)
                    self.setupExpenseRelationships(cdRecurringExpense, expense: recurringExpense, context: context)
                }
            }
        }

        await loadRecentExpenses()
    }

    /// Retrieves an expense by ID
    /// - Parameter id: The expense ID
    /// - Returns: Expense if found, nil otherwise
    /// - Throws: Core Data error if fetch fails
    func getExpense(by id: String) async throws -> Expense? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            let results = try context.fetch(request)
            return results.first?.toExpense()
        }
    }

    /// Retrieves expenses with filtering and sorting options
    /// - Parameters:
    ///   - startDate: Start date filter (optional)
    ///   - endDate: End date filter (optional)
    ///   - categoryIds: Category ID filters (optional)
    ///   - subCategoryIds: SubCategory ID filters (optional)
    ///   - status: Status filter (optional)
    ///   - sortBy: Sort field
    ///   - ascending: Sort direction
    ///   - limit: Maximum number of results
    /// - Returns: Array of expenses
    /// - Throws: Core Data error if fetch fails
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
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()

            var predicates: [NSPredicate] = []

            // Date range filter
            if let startDate = startDate {
                predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
            }
            if let endDate = endDate {
                predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
            }

            // Category filter
            if let categoryIds = categoryIds, !categoryIds.isEmpty {
                predicates.append(NSPredicate(format: "categoryId IN %@", categoryIds))
            }

            // SubCategory filter
            if let subCategoryIds = subCategoryIds, !subCategoryIds.isEmpty {
                predicates.append(NSPredicate(format: "subCategoryId IN %@", subCategoryIds))
            }

            // Status filter
            if let status = status {
                predicates.append(NSPredicate(format: "status == %@", status.rawValue))
            }

            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            // Sorting
            request.sortDescriptors = [NSSortDescriptor(key: sortBy.coreDataKey, ascending: ascending)]

            // Limit
            if let limit = limit {
                request.fetchLimit = limit
            }

            let results = try context.fetch(request)
            return results.map { $0.toExpense() }
        }
    }

    /// Updates an existing expense
    /// - Parameter expense: The updated expense
    /// - Throws: Core Data error if update fails
    func updateExpense(_ expense: Expense) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", expense.id)
            request.fetchLimit = 1

            guard let cdExpense = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            cdExpense.update(from: expense)
            self.setupExpenseRelationships(cdExpense, expense: expense, context: context)
        }

        await loadRecentExpenses()
    }

    /// Deletes an expense
    /// - Parameter id: The expense ID to delete
    /// - Throws: Core Data error if deletion fails
    func deleteExpense(by id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            guard let cdExpense = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            // If this is a parent expense with recurring children, delete them too
            if cdExpense.isRecurring == false && cdExpense.recurrenceType != RecurrenceType.none.rawValue {
                let childRequest: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
                childRequest.predicate = NSPredicate(format: "parentExpenseId == %@", id)

                let childExpenses = try context.fetch(childRequest)
                for childExpense in childExpenses {
                    context.delete(childExpense)
                }
            }

            context.delete(cdExpense)
        }

        await loadRecentExpenses()
    }

    // MARK: - Bulk Operations

    /// Deletes multiple expenses
    /// - Parameter ids: Array of expense IDs to delete
    /// - Throws: Core Data error if deletion fails
    func deleteExpenses(by ids: [String]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)

            let expenses = try context.fetch(request)
            for expense in expenses {
                context.delete(expense)
            }
        }

        await loadRecentExpenses()
    }

    /// Updates the status of multiple expenses
    /// - Parameters:
    ///   - ids: Array of expense IDs
    ///   - status: New status
    /// - Throws: Core Data error if update fails
    func updateExpensesStatus(_ ids: [String], status: ExpenseStatus) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)

            let expenses = try context.fetch(request)
            for expense in expenses {
                expense.status = status.rawValue
                expense.updatedAt = Date()
            }
        }

        await loadRecentExpenses()
    }

    // MARK: - Analytics and Reporting

    /// Gets expenses grouped by category for a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Dictionary with category ID as key and total amount as value
    /// - Throws: Core Data error if calculation fails
    func getExpensesByCategory(startDate: Date, endDate: Date) async throws -> [String: Double] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND status == %@",
                                          startDate as NSDate, endDate as NSDate, ExpenseStatus.confirmed.rawValue)

            let expenses = try context.fetch(request)
            var categoryTotals: [String: Double] = [:]

            for expense in expenses {
                let categoryId = expense.categoryId ?? ""
                categoryTotals[categoryId, default: 0] += expense.amount
            }

            return categoryTotals
        }
    }

    /// Gets expenses grouped by subcategory for a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Dictionary with subcategory ID as key and total amount as value
    /// - Throws: Core Data error if calculation fails
    func getExpensesBySubCategory(startDate: Date, endDate: Date) async throws -> [String: Double] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND status == %@",
                                          startDate as NSDate, endDate as NSDate, ExpenseStatus.confirmed.rawValue)

            let expenses = try context.fetch(request)
            var subCategoryTotals: [String: Double] = [:]

            for expense in expenses {
                let subCategoryId = expense.subCategoryId ?? ""
                subCategoryTotals[subCategoryId, default: 0] += expense.amount
            }

            return subCategoryTotals
        }
    }

    /// Gets daily expense totals for a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Dictionary with date string as key and total amount as value
    /// - Throws: Core Data error if calculation fails
    func getDailyExpenseTotals(startDate: Date, endDate: Date) async throws -> [String: Double] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND status == %@",
                                          startDate as NSDate, endDate as NSDate, ExpenseStatus.confirmed.rawValue)

            let expenses = try context.fetch(request)
            var dailyTotals: [String: Double] = [:]

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for expense in expenses {
                let dateKey = formatter.string(from: expense.date ?? Date())
                dailyTotals[dateKey, default: 0] += expense.amount
            }

            return dailyTotals
        }
    }

    /// Gets monthly expense totals for a year
    /// - Parameter year: The year to analyze
    /// - Returns: Dictionary with month string as key and total amount as value
    /// - Throws: Core Data error if calculation fails
    func getMonthlyExpenseTotals(for year: Int) async throws -> [String: Double] {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!

        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND status == %@",
                                          startDate as NSDate, endDate as NSDate, ExpenseStatus.confirmed.rawValue)

            let expenses = try context.fetch(request)
            var monthlyTotals: [String: Double] = [:]

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"

            for expense in expenses {
                let monthKey = formatter.string(from: expense.date ?? Date())
                monthlyTotals[monthKey, default: 0] += expense.amount
            }

            return monthlyTotals
        }
    }

    /// Gets expense statistics for a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Dictionary with various statistics
    /// - Throws: Core Data error if calculation fails
    func getExpenseStatistics(startDate: Date, endDate: Date) async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@ AND status == %@",
                                          startDate as NSDate, endDate as NSDate, ExpenseStatus.confirmed.rawValue)

            let expenses = try context.fetch(request)
            let amounts = expenses.map { $0.amount }

            let totalAmount = amounts.reduce(0, +)
            let averageAmount = amounts.isEmpty ? 0 : totalAmount / Double(amounts.count)
            let maxAmount = amounts.max() ?? 0
            let minAmount = amounts.min() ?? 0
            let expenseCount = amounts.count

            // Calculate median
            let sortedAmounts = amounts.sorted()
            let median: Double
            if sortedAmounts.isEmpty {
                median = 0
            } else if sortedAmounts.count % 2 == 0 {
                let mid1 = sortedAmounts[sortedAmounts.count / 2 - 1]
                let mid2 = sortedAmounts[sortedAmounts.count / 2]
                median = (mid1 + mid2) / 2
            } else {
                median = sortedAmounts[sortedAmounts.count / 2]
            }

            return [
                "totalAmount": totalAmount,
                "averageAmount": averageAmount,
                "medianAmount": median,
                "maxAmount": maxAmount,
                "minAmount": minAmount,
                "expenseCount": expenseCount
            ]
        }
    }

    // MARK: - Search Operations

    /// Searches expenses by description
    /// - Parameter searchText: The search term
    /// - Returns: Array of matching expenses
    /// - Throws: Core Data error if search fails
    func searchExpenses(by searchText: String) async throws -> [Expense] {
        guard !searchText.isEmpty else {
            return try await getExpenses(limit: 50)
        }

        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "expenseDescription CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = 100

            let results = try context.fetch(request)
            return results.map { $0.toExpense() }
        }
    }

    /// Gets expenses by tags
    /// - Parameter tags: Array of tags to search for
    /// - Returns: Array of expenses containing any of the tags
    /// - Throws: Core Data error if search fails
    func getExpensesByTags(_ tags: [String]) async throws -> [Expense] {
        guard !tags.isEmpty else { return [] }

        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()

            let tagPredicates = tags.map { tag in
                NSPredicate(format: "tags CONTAINS[cd] %@", tag)
            }
            request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: tagPredicates)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let results = try context.fetch(request)
            return results.map { $0.toExpense() }
        }
    }

    // MARK: - Recurring Expenses

    /// Gets all recurring expense templates (parent expenses with recurrence)
    /// - Returns: Array of recurring expense templates
    /// - Throws: Core Data error if fetch fails
    func getRecurringExpenseTemplates() async throws -> [Expense] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "isRecurring == NO AND recurrenceType != %@", RecurrenceType.none.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let results = try context.fetch(request)
            return results.map { $0.toExpense() }
        }
    }

    /// Gets all recurring expense instances for a parent expense
    /// - Parameter parentId: The parent expense ID
    /// - Returns: Array of recurring expense instances
    /// - Throws: Core Data error if fetch fails
    func getRecurringExpenseInstances(for parentId: String) async throws -> [Expense] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            request.predicate = NSPredicate(format: "parentExpenseId == %@", parentId)
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            let results = try context.fetch(request)
            return results.map { $0.toExpense() }
        }
    }

    // MARK: - Data Loading

    /// Loads recent expenses (last 30 days)
    private func loadRecentExpenses() {
        Task {
            do {
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let recent = try await getExpenses(
                    startDate: thirtyDaysAgo,
                    endDate: Date(),
                    sortBy: .date,
                    ascending: false,
                    limit: 100
                )

                await MainActor.run {
                    self.recentExpenses = recent
                }
            } catch {
                print("Failed to load recent expenses: \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    /// Sets up relationships for an expense entity
    private func setupExpenseRelationships(_ cdExpense: CDExpense, expense: Expense, context: NSManagedObjectContext) {
        // Set up category relationship
        let categoryRequest: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "id == %@", expense.categoryId)
        categoryRequest.fetchLimit = 1

        if let category = try? context.fetch(categoryRequest).first {
            cdExpense.category = category
        }

        // Set up subcategory relationship
        let subCategoryRequest: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
        subCategoryRequest.predicate = NSPredicate(format: "id == %@", expense.subCategoryId)
        subCategoryRequest.fetchLimit = 1

        if let subCategory = try? context.fetch(subCategoryRequest).first {
            cdExpense.subCategory = subCategory
        }
    }
}

// MARK: - Supporting Types

enum ExpenseSortField: String, CaseIterable {
    case date = "date"
    case amount = "amount"
    case description = "expenseDescription"
    case category = "categoryId"
    case createdAt = "createdAt"

    var coreDataKey: String {
        return rawValue
    }

    var displayName: String {
        switch self {
        case .date: return L("sort_by_date")
        case .amount: return L("sort_by_amount")
        case .description: return L("sort_by_description")
        case .category: return L("sort_by_category")
        case .createdAt: return L("sort_by_created")
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension ExpenseDataAccess {
    static let preview: ExpenseDataAccess = {
        return ExpenseDataAccess(coreDataStack: CoreDataStack.preview)
    }()
}
#endif