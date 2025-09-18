//
//  CDExpense+CoreDataClass.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

@objc(CDExpense)
public class CDExpense: NSManagedObject {

    /// Converts Core Data entity to Swift model
    func toExpense() -> Expense {
        let recurrenceType = RecurrenceType(rawValue: self.recurrenceType ?? "") ?? .none
        let status = ExpenseStatus(rawValue: self.status ?? "") ?? .confirmed
        let tagsArray = tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []

        return Expense(
            id: id ?? UUID().uuidString,
            amount: amount,
            currency: currency ?? "TRY",
            categoryId: categoryId ?? "",
            subCategoryId: subCategoryId ?? "",
            description: expenseDescription ?? "",
            date: date ?? Date(),
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            dailyLimitAtCreation: dailyLimitAtCreation,
            monthlyLimitAtCreation: monthlyLimitAtCreation,
            yearlyLimitAtCreation: yearlyLimitAtCreation,
            recurrenceType: recurrenceType,
            recurrenceEndDate: recurrenceEndDate,
            customRecurrenceInterval: Int(customRecurrenceInterval),
            status: status,
            tags: tagsArray,
            notes: notes ?? "",
            receiptImagePath: receiptImagePath,
            location: location,
            isRecurring: isRecurring,
            parentExpenseId: parentExpenseId
        )
    }

    /// Updates Core Data entity from Swift model
    func update(from expense: Expense) {
        id = expense.id
        amount = expense.amount
        currency = expense.currency
        categoryId = expense.categoryId
        subCategoryId = expense.subCategoryId
        expenseDescription = expense.description
        date = expense.date
        createdAt = expense.createdAt
        updatedAt = expense.updatedAt
        dailyLimitAtCreation = expense.dailyLimitAtCreation
        monthlyLimitAtCreation = expense.monthlyLimitAtCreation
        yearlyLimitAtCreation = expense.yearlyLimitAtCreation
        recurrenceType = expense.recurrenceType.rawValue
        recurrenceEndDate = expense.recurrenceEndDate
        customRecurrenceInterval = Int32(expense.customRecurrenceInterval)
        status = expense.status.rawValue
        tags = expense.tags.joined(separator: ",")
        notes = expense.notes
        receiptImagePath = expense.receiptImagePath
        location = expense.location
        isRecurring = expense.isRecurring
        parentExpenseId = expense.parentExpenseId
    }

    /// Creates a new CDExpense from an Expense model
    /// - Parameters:
    ///   - expense: The Expense model
    ///   - context: The managed object context
    /// - Returns: New CDExpense instance
    static func from(_ expense: Expense, context: NSManagedObjectContext) -> CDExpense {
        let cdExpense = CDExpense(context: context)
        cdExpense.update(from: expense)
        return cdExpense
    }
}