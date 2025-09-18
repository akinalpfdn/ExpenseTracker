//
//  DailyData.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import Foundation
import SwiftUI

/// Represents daily expense tracking data with comprehensive analytics and visual progress indicators
/// This model encapsulates all daily financial metrics and provides computed properties for UI display
struct DailyData: Identifiable, Hashable, Codable {
    let id: String
    let date: Date
    let totalAmount: Double
    let expenseCount: Int
    let dailyLimit: Double
    let monthlyLimit: Double
    let yearlyLimit: Double
    let expenses: [Expense]
    let isWorkingDay: Bool
    let targetSavings: Double
    let actualSavings: Double

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        date: Date,
        totalAmount: Double = 0.0,
        expenseCount: Int = 0,
        dailyLimit: Double = 0.0,
        monthlyLimit: Double = 0.0,
        yearlyLimit: Double = 0.0,
        expenses: [Expense] = [],
        isWorkingDay: Bool = true,
        targetSavings: Double = 0.0,
        actualSavings: Double = 0.0
    ) {
        self.id = id
        self.date = date
        self.totalAmount = totalAmount
        self.expenseCount = expenseCount
        self.dailyLimit = dailyLimit
        self.monthlyLimit = monthlyLimit
        self.yearlyLimit = yearlyLimit
        self.expenses = expenses
        self.isWorkingDay = isWorkingDay
        self.targetSavings = targetSavings
        self.actualSavings = actualSavings
    }

    // MARK: - Progress and Limit Calculations

    /// Calculates progress percentage against daily limit
    var progressPercentage: Double {
        guard dailyLimit > 0 else { return 0 }
        return min(totalAmount / dailyLimit, 1.0)
    }

    /// Determines if daily limit has been exceeded
    var isOverLimit: Bool {
        return totalAmount > dailyLimit && dailyLimit > 0
    }

    /// Calculates remaining budget for the day
    var remainingBudget: Double {
        return max(dailyLimit - totalAmount, 0)
    }

    /// Calculates overspent amount if over limit
    var overspentAmount: Double {
        return max(totalAmount - dailyLimit, 0)
    }

    /// Calculates efficiency score (0-100) based on spending vs limits
    var efficiencyScore: Double {
        guard dailyLimit > 0 else { return 0 }
        let efficiency = (dailyLimit - totalAmount) / dailyLimit
        return max(min(efficiency * 100, 100), 0)
    }

    // MARK: - Visual Progress Indicators

    /// Returns color gradient for progress visualization
    var progressColors: [Color] {
        if isOverLimit {
            return [.red, .red, .red, .red]
        } else if progressPercentage < 0.3 {
            return [.green, .green, .green, .green]
        } else if progressPercentage < 0.6 {
            return [.green, .green, .yellow, .yellow]
        } else if progressPercentage < 0.9 {
            return [.green, .yellow, .orange, .orange]
        } else {
            return [.green, .yellow, .orange, .red]
        }
    }

    /// Returns primary color based on spending status
    var statusColor: Color {
        if isOverLimit {
            return .red
        } else if progressPercentage > 0.8 {
            return .orange
        } else if progressPercentage > 0.6 {
            return .yellow
        } else {
            return .green
        }
    }

    /// Returns SF Symbol name for current status
    var statusIconName: String {
        if isOverLimit {
            return "exclamationmark.triangle.fill"
        } else if progressPercentage > 0.8 {
            return "exclamationmark.circle.fill"
        } else if progressPercentage > 0.6 {
            return "minus.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    // MARK: - Date Formatting

    /// Returns localized abbreviated day name (first letter)
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "E"
        let dayName = formatter.string(from: date)
        return String(dayName.prefix(1)).uppercased()
    }

    /// Returns day number as string
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    /// Returns full localized date string
    var fullDateString: String {
        return DateConverters.dateToDisplayString(date)
    }

    /// Returns formatted day and month (e.g., "15 Mar")
    var dayMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    // MARK: - Date Status

    /// Checks if this data represents today
    var isToday: Bool {
        return Calendar.current.isDateInToday(date)
    }

    /// Checks if this data represents selected date
    var isSelected: Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }

    /// Checks if the date is in the past
    var isPast: Bool {
        return date < Date().startOfDay
    }

    /// Checks if the date is in the future
    var isFuture: Bool {
        return date > Date().startOfDay
    }

    /// Checks if the date is a weekend
    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }

    // MARK: - Expense Analysis

    /// Groups expenses by category
    var expensesByCategory: [String: [Expense]] {
        return Dictionary(grouping: expenses) { $0.category.rawValue }
    }

    /// Returns the most expensive category for the day
    var topSpendingCategory: String? {
        let categoryTotals = expensesByCategory.mapValues { expenses in
            expenses.reduce(0) { $0 + $1.amount }
        }
        return categoryTotals.max(by: { $0.value < $1.value })?.key
    }

    /// Returns average expense amount for the day
    var averageExpenseAmount: Double {
        guard expenseCount > 0 else { return 0 }
        return totalAmount / Double(expenseCount)
    }

    /// Returns the largest single expense for the day
    var largestExpense: Expense? {
        return expenses.max(by: { $0.amount < $1.amount })
    }

    /// Returns the smallest single expense for the day
    var smallestExpense: Expense? {
        return expenses.min(by: { $0.amount < $1.amount })
    }

    // MARK: - Savings Analysis

    /// Calculates savings performance compared to target
    var savingsPerformance: Double {
        guard targetSavings > 0 else { return 0 }
        return (actualSavings / targetSavings) * 100
    }

    /// Determines if savings target was met
    var didMeetSavingsTarget: Bool {
        return actualSavings >= targetSavings
    }

    /// Calculates variance from target savings
    var savingsVariance: Double {
        return actualSavings - targetSavings
    }

    // MARK: - Business Logic Methods

    /// Creates a copy with updated expenses and recalculated totals
    /// - Parameter newExpenses: Updated list of expenses
    /// - Returns: New DailyData instance with recalculated values
    func withUpdatedExpenses(_ newExpenses: [Expense]) -> DailyData {
        let newTotal = newExpenses.reduce(0) { $0 + $1.amount }
        let newSavings = dailyLimit - newTotal

        return DailyData(
            id: self.id,
            date: self.date,
            totalAmount: newTotal,
            expenseCount: newExpenses.count,
            dailyLimit: self.dailyLimit,
            monthlyLimit: self.monthlyLimit,
            yearlyLimit: self.yearlyLimit,
            expenses: newExpenses,
            isWorkingDay: self.isWorkingDay,
            targetSavings: self.targetSavings,
            actualSavings: max(newSavings, 0)
        )
    }

    /// Adds a new expense and returns updated DailyData
    /// - Parameter expense: Expense to add
    /// - Returns: New DailyData instance with the expense added
    func addingExpense(_ expense: Expense) -> DailyData {
        var newExpenses = expenses
        newExpenses.append(expense)
        return withUpdatedExpenses(newExpenses)
    }

    /// Removes an expense and returns updated DailyData
    /// - Parameter expenseId: ID of expense to remove
    /// - Returns: New DailyData instance with the expense removed
    func removingExpense(withId expenseId: String) -> DailyData {
        let newExpenses = expenses.filter { $0.id != expenseId }
        return withUpdatedExpenses(newExpenses)
    }

    /// Updates an existing expense and returns updated DailyData
    /// - Parameter updatedExpense: The updated expense
    /// - Returns: New DailyData instance with the expense updated
    func updatingExpense(_ updatedExpense: Expense) -> DailyData {
        let newExpenses = expenses.map { expense in
            expense.id == updatedExpense.id ? updatedExpense : expense
        }
        return withUpdatedExpenses(newExpenses)
    }

    /// Generates a summary report for the day
    /// - Returns: Formatted string summary of the day's financial activity
    func generateSummaryReport() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current

        let totalFormatted = formatter.string(from: NSNumber(value: totalAmount)) ?? "0"
        let limitFormatted = formatter.string(from: NSNumber(value: dailyLimit)) ?? "0"
        let remainingFormatted = formatter.string(from: NSNumber(value: remainingBudget)) ?? "0"

        var report = """
        \(L("daily_summary_title")): \(fullDateString)
        \(L("total_spent")): \(totalFormatted)
        \(L("daily_limit")): \(limitFormatted)
        \(L("remaining_budget")): \(remainingFormatted)
        \(L("expense_count")): \(expenseCount)
        """

        if let topCategory = topSpendingCategory {
            report += "\n\(L("top_category")): \(topCategory)"
        }

        if isOverLimit {
            let overspentFormatted = formatter.string(from: NSNumber(value: overspentAmount)) ?? "0"
            report += "\n⚠️ \(L("over_limit_by")): \(overspentFormatted)"
        }

        return report
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(totalAmount)
        hasher.combine(expenseCount)
    }

    static func == (lhs: DailyData, rhs: DailyData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.totalAmount == rhs.totalAmount &&
               lhs.expenseCount == rhs.expenseCount
    }
}
