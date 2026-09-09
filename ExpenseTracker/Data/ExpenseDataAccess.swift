//
//  ExpenseDataAccess.swift
//  ExpenseTracker
//
//  Created by migration from Android ExpenseDao.kt
//

import Foundation
import CoreData

class ExpenseDataAccess {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    // MARK: - Expense Operations

    func getAllExpenses() async throws -> [Expense] {
        return try await context.perform {
            let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            let entities = try self.context.fetch(request)
            return entities.compactMap { entity in
                guard !entity.isDeleted else { return nil }
                return Expense(from: entity)
            }
        }
    }

    func getExpensesForDateRange(startDate: Date, endDate: Date) async throws -> [Expense] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { Expense(from: $0) }
    }

    func insertExpense(_ expense: Expense) async throws {
        try await context.perform {
            _ = expense.toCoreData(context: self.context)
            try self.context.save()
        }
    }

    /// Inserts many expenses under a single save.
    ///
    /// A recurring expense is stored as one row per occurrence, so a daily one with no
    /// end date is around 365 rows. Inserting those one at a time meant 365 saves on
    /// the view context, each writing to the store and publishing changes — enough to
    /// block the UI for seconds. One save also makes the batch atomic: a failure part
    /// way through leaves no half-written series.
    func insertExpenses(_ expenses: [Expense]) async throws {
        guard !expenses.isEmpty else { return }

        try await context.perform {
            do {
                for expense in expenses {
                    _ = expense.toCoreData(context: self.context)
                }
                try self.context.save()
            } catch {
                self.context.rollback()
                throw error
            }
        }
    }

    func updateExpense(_ expense: Expense) async throws {
        try await context.perform {
            let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", expense.id)
            request.fetchLimit = 1

            let entities = try self.context.fetch(request)
            if let entity = entities.first {
                entity.amount = expense.amount
                entity.currency = expense.currency
                entity.categoryId = expense.categoryId
                entity.subCategoryId = expense.subCategoryId
                entity.desc = expense.description.isEmpty ? nil : expense.description
                entity.date = expense.date
                entity.dailyLimitAtCreation = expense.dailyLimitAtCreation
                entity.monthlyLimitAtCreation = expense.monthlyLimitAtCreation
                entity.exchangeRate = expense.exchangeRate ?? 0
                entity.recurrenceType = expense.recurrenceType.rawValue
                entity.endDate = expense.endDate
                entity.recurrenceGroupId = expense.recurrenceGroupId
                try self.context.save()
            }
        }
    }

    func deleteExpense(_ expense: Expense) async throws {
        try await context.perform {
            let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", expense.id)

            let entities = try self.context.fetch(request)
            for entity in entities {
                self.context.delete(entity)
            }
            try self.context.save()
        }
    }

    /// Applies many updates under a single save, with one fetch instead of one per row.
    ///
    /// Editing a recurring series rewrites every occurrence from a date onwards, which
    /// for a daily series is hundreds of rows.
    func updateExpenses(_ expenses: [Expense]) async throws {
        guard !expenses.isEmpty else { return }

        try await context.perform {
            do {
                let byId = Dictionary(uniqueKeysWithValues: expenses.map { ($0.id, $0) })

                let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id IN %@", Array(byId.keys))

                for entity in try self.context.fetch(request) {
                    guard let id = entity.id, let expense = byId[id] else { continue }

                    entity.amount = expense.amount
                    entity.currency = expense.currency
                    entity.categoryId = expense.categoryId
                    entity.subCategoryId = expense.subCategoryId
                    entity.desc = expense.description.isEmpty ? nil : expense.description
                    entity.date = expense.date
                    entity.dailyLimitAtCreation = expense.dailyLimitAtCreation
                    entity.monthlyLimitAtCreation = expense.monthlyLimitAtCreation
                    entity.exchangeRate = expense.exchangeRate ?? 0
                    entity.recurrenceType = expense.recurrenceType.rawValue
                    entity.endDate = expense.endDate
                    entity.recurrenceGroupId = expense.recurrenceGroupId
                }

                try self.context.save()
            } catch {
                self.context.rollback()
                throw error
            }
        }
    }

    /// Deletes many expenses under a single save. Same reasoning as the bulk insert:
    /// cancelling a daily recurring series is hundreds of rows.
    func deleteExpenses(_ expenses: [Expense]) async throws {
        guard !expenses.isEmpty else { return }

        try await context.perform {
            do {
                let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id IN %@", expenses.map(\.id))

                for entity in try self.context.fetch(request) {
                    self.context.delete(entity)
                }

                try self.context.save()
            } catch {
                self.context.rollback()
                throw error
            }
        }
    }

    func deleteExpenseById(_ expenseId: String) async throws {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expenseId)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func getTotalForDateRange(startDate: Date, endDate: Date) async throws -> Double? {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)

        let entities = try context.fetch(request)
        let total = entities.reduce(0) { $0 + $1.amount }
        return total > 0 ? total : nil
    }

    func getAllExpensesDirect() async throws -> [Expense] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { Expense(from: $0) }
    }
}
