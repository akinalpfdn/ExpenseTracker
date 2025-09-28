//
//  ExpenseRepository.swift
//  ExpenseTracker
//
//  Created by migration from Android ExpenseRepository.kt
//

import Foundation
import Combine

class ExpenseRepository: ObservableObject {
    private let expenseDataAccess: ExpenseDataAccess
    private let preferencesManager: PreferencesManager

    init(expenseDataAccess: ExpenseDataAccess = ExpenseDataAccess(), preferencesManager: PreferencesManager = PreferencesManager()) {
        self.expenseDataAccess = expenseDataAccess
        self.preferencesManager = preferencesManager
    }

    // MARK: - Expense Operations

    func getAllExpenses() async throws -> [Expense] {
        return try await expenseDataAccess.getAllExpenses()
    }

    func getExpensesForDateRange(startDate: Date, endDate: Date) async throws -> [Expense] {
        return try await expenseDataAccess.getExpensesForDateRange(startDate: startDate, endDate: endDate)
    }

    func insertExpense(_ expense: Expense) async throws {
        try await expenseDataAccess.insertExpense(expense)
    }

    func updateExpense(_ expense: Expense) async throws {
        try await expenseDataAccess.updateExpense(expense)
    }

    func deleteExpense(_ expense: Expense) async throws {
        try await expenseDataAccess.deleteExpense(expense)
    }

    func deleteExpenseById(_ expenseId: String) async throws {
        try await expenseDataAccess.deleteExpenseById(expenseId)
    }

    func getTotalForDateRange(startDate: Date, endDate: Date) async throws -> Double {
        return try await expenseDataAccess.getTotalForDateRange(startDate: startDate, endDate: endDate) ?? 0.0
    }

    func getAllExpensesDirect() async throws -> [Expense] {
        return try await expenseDataAccess.getAllExpensesDirect()
    }
}