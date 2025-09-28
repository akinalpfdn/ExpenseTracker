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
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { Expense(from: $0) }
    }

    func getExpensesForDateRange(startDate: Date, endDate: Date) async throws -> [Expense] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { Expense(from: $0) }
    }

    func insertExpense(_ expense: Expense) async throws {
        let entity = expense.toCoreData(context: context)
        try context.save()
    }

    func updateExpense(_ expense: Expense) async throws {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.amount = expense.amount
            entity.currency = expense.currency
            entity.categoryId = expense.categoryId
            entity.subCategoryId = expense.subCategoryId
            entity.desc = expense.description
            entity.date = expense.date
            entity.dailyLimitAtCreation = expense.dailyLimitAtCreation
            entity.monthlyLimitAtCreation = expense.monthlyLimitAtCreation
            entity.exchangeRate = expense.exchangeRate ?? 0
            entity.recurrenceType = expense.recurrenceType.rawValue
            entity.endDate = expense.endDate
            entity.recurrenceGroupId = expense.recurrenceGroupId
            try context.save()
        }
    }

    func deleteExpense(_ expense: Expense) async throws {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
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
