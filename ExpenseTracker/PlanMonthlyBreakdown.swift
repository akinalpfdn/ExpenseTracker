//
//  PlanMonthlyBreakdown.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI

/// Represents a monthly breakdown of a financial plan with detailed calculations and progress tracking
/// Provides month-by-month financial analytics and variance analysis
struct PlanMonthlyBreakdown: Identifiable, Hashable, Codable {
    let id: String
    let planId: String
    let month: String // Format: "YYYY-MM"
    let year: Int
    let monthNumber: Int
    var plannedIncome: Double
    var actualIncome: Double
    var plannedExpenses: Double
    var actualExpenses: Double
    var plannedSavings: Double
    var actualSavings: Double
    var fixedExpenses: Double
    var variableExpenses: Double
    var emergencyFundContribution: Double
    var investmentContribution: Double
    var debtPayment: Double
    var categoryBreakdown: [String: CategoryMonthlyData] // categoryId -> data
    var expensesBySubCategory: [String: Double] // subCategoryId -> amount
    var notes: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        planId: String,
        month: String,
        year: Int,
        monthNumber: Int,
        plannedIncome: Double = 0.0,
        actualIncome: Double = 0.0,
        plannedExpenses: Double = 0.0,
        actualExpenses: Double = 0.0,
        plannedSavings: Double = 0.0,
        actualSavings: Double = 0.0,
        fixedExpenses: Double = 0.0,
        variableExpenses: Double = 0.0,
        emergencyFundContribution: Double = 0.0,
        investmentContribution: Double = 0.0,
        debtPayment: Double = 0.0,
        categoryBreakdown: [String: CategoryMonthlyData] = [:],
        expensesBySubCategory: [String: Double] = [:],
        notes: String = "",
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.planId = planId
        self.month = month
        self.year = year
        self.monthNumber = monthNumber
        self.plannedIncome = plannedIncome
        self.actualIncome = actualIncome
        self.plannedExpenses = plannedExpenses
        self.actualExpenses = actualExpenses
        self.plannedSavings = plannedSavings
        self.actualSavings = actualSavings
        self.fixedExpenses = fixedExpenses
        self.variableExpenses = variableExpenses
        self.emergencyFundContribution = emergencyFundContribution
        self.investmentContribution = investmentContribution
        self.debtPayment = debtPayment
        self.categoryBreakdown = categoryBreakdown
        self.expensesBySubCategory = expensesBySubCategory
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns the Date object for this month
    var monthDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month) ?? Date()
    }

    /// Returns a localized month name
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthDate)
    }

    /// Returns a short month name
    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM"
        return formatter.string(from: monthDate)
    }

    /// Calculates the planned net income (income - expenses)
    var plannedNetIncome: Double {
        return plannedIncome - plannedExpenses
    }

    /// Calculates the actual net income (income - expenses)
    var actualNetIncome: Double {
        return actualIncome - actualExpenses
    }

    /// Calculates the income variance (actual - planned)
    var incomeVariance: Double {
        return actualIncome - plannedIncome
    }

    /// Calculates the expense variance (planned - actual, positive is under budget)
    var expenseVariance: Double {
        return plannedExpenses - actualExpenses
    }

    /// Calculates the savings variance (actual - planned)
    var savingsVariance: Double {
        return actualSavings - plannedSavings
    }

    /// Calculates the net variance (overall plan vs actual)
    var netVariance: Double {
        return actualNetIncome - plannedNetIncome
    }

    /// Returns the income achievement percentage
    var incomeAchievementPercentage: Double {
        guard plannedIncome > 0 else { return 0 }
        return (actualIncome / plannedIncome) * 100
    }

    /// Returns the expense control percentage (lower is better)
    var expenseControlPercentage: Double {
        guard plannedExpenses > 0 else { return actualExpenses == 0 ? 100 : 0 }
        return (actualExpenses / plannedExpenses) * 100
    }

    /// Returns the savings achievement percentage
    var savingsAchievementPercentage: Double {
        guard plannedSavings > 0 else { return actualSavings > 0 ? 100 : 0 }
        return (actualSavings / plannedSavings) * 100
    }

    /// Returns the total expenses (fixed + variable)
    var totalExpenses: Double {
        return fixedExpenses + variableExpenses
    }

    /// Returns the savings rate for this month
    var savingsRate: Double {
        guard actualIncome > 0 else { return 0 }
        return (actualSavings / actualIncome) * 100
    }

    /// Checks if this month is in the past
    var isPastMonth: Bool {
        return monthDate < Date().startOfMonth
    }

    /// Checks if this month is the current month
    var isCurrentMonth: Bool {
        return DateConverters.isSameMonth(monthDate, Date())
    }

    /// Checks if this month is in the future
    var isFutureMonth: Bool {
        return monthDate > Date().startOfMonth
    }

    /// Returns the financial health score (0-100) for this month
    var financialHealthScore: Double {
        var score = 0.0

        // Income achievement (30% weight)
        score += min(incomeAchievementPercentage, 100) * 0.3

        // Expense control (30% weight) - inverse scoring
        let expenseScore = max(100 - expenseControlPercentage, 0)
        score += expenseScore * 0.3

        // Savings achievement (40% weight)
        score += min(savingsAchievementPercentage, 100) * 0.4

        return min(score, 100)
    }

    // MARK: - Category Analysis

    /// Returns the category with the highest actual expenses
    var topExpenseCategory: String? {
        return categoryBreakdown.max(by: { $0.value.actualExpenses < $1.value.actualExpenses })?.key
    }

    /// Returns the category with the highest variance (over budget)
    var mostOverBudgetCategory: String? {
        return categoryBreakdown.max(by: { $0.value.expenseVariance < $1.value.expenseVariance })?.key
    }

    /// Returns the category with the best performance (under budget)
    var bestPerformingCategory: String? {
        return categoryBreakdown.min(by: { $0.value.expenseVariance < $1.value.expenseVariance })?.key
    }

    /// Calculates total variance across all categories
    var totalCategoryVariance: Double {
        return categoryBreakdown.values.reduce(0) { $0 + $1.expenseVariance }
    }

    // MARK: - Business Logic Methods

    /// Creates a copy of the breakdown with updated properties
    /// - Parameter updates: Dictionary of property updates
    /// - Returns: New PlanMonthlyBreakdown instance with updated properties
    func updated(with updates: [String: Any]) -> PlanMonthlyBreakdown {
        return PlanMonthlyBreakdown(
            id: self.id,
            planId: self.planId,
            month: self.month,
            year: self.year,
            monthNumber: self.monthNumber,
            plannedIncome: updates["plannedIncome"] as? Double ?? self.plannedIncome,
            actualIncome: updates["actualIncome"] as? Double ?? self.actualIncome,
            plannedExpenses: updates["plannedExpenses"] as? Double ?? self.plannedExpenses,
            actualExpenses: updates["actualExpenses"] as? Double ?? self.actualExpenses,
            plannedSavings: updates["plannedSavings"] as? Double ?? self.plannedSavings,
            actualSavings: updates["actualSavings"] as? Double ?? self.actualSavings,
            fixedExpenses: updates["fixedExpenses"] as? Double ?? self.fixedExpenses,
            variableExpenses: updates["variableExpenses"] as? Double ?? self.variableExpenses,
            emergencyFundContribution: updates["emergencyFundContribution"] as? Double ?? self.emergencyFundContribution,
            investmentContribution: updates["investmentContribution"] as? Double ?? self.investmentContribution,
            debtPayment: updates["debtPayment"] as? Double ?? self.debtPayment,
            categoryBreakdown: updates["categoryBreakdown"] as? [String: CategoryMonthlyData] ?? self.categoryBreakdown,
            expensesBySubCategory: updates["expensesBySubCategory"] as? [String: Double] ?? self.expensesBySubCategory,
            notes: updates["notes"] as? String ?? self.notes,
            isCompleted: updates["isCompleted"] as? Bool ?? self.isCompleted,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }

    /// Updates actual income for the month
    /// - Parameter income: New actual income amount
    /// - Returns: Updated PlanMonthlyBreakdown instance
    func withActualIncome(_ income: Double) -> PlanMonthlyBreakdown {
        let newActualSavings = income - actualExpenses
        return updated(with: [
            "actualIncome": income,
            "actualSavings": max(newActualSavings, 0)
        ])
    }

    /// Updates actual expenses for the month
    /// - Parameter expenses: New actual expenses amount
    /// - Returns: Updated PlanMonthlyBreakdown instance
    func withActualExpenses(_ expenses: Double) -> PlanMonthlyBreakdown {
        let newActualSavings = actualIncome - expenses
        return updated(with: [
            "actualExpenses": expenses,
            "actualSavings": max(newActualSavings, 0)
        ])
    }

    /// Updates category breakdown data
    /// - Parameters:
    ///   - categoryId: Category identifier
    ///   - data: Category monthly data
    /// - Returns: Updated PlanMonthlyBreakdown instance
    func updatingCategory(_ categoryId: String, with data: CategoryMonthlyData) -> PlanMonthlyBreakdown {
        var newCategoryBreakdown = categoryBreakdown
        newCategoryBreakdown[categoryId] = data
        return updated(with: ["categoryBreakdown": newCategoryBreakdown])
    }

    /// Records an expense in a subcategory
    /// - Parameters:
    ///   - subCategoryId: Subcategory identifier
    ///   - amount: Expense amount
    /// - Returns: Updated PlanMonthlyBreakdown instance
    func recordingExpense(subCategoryId: String, amount: Double) -> PlanMonthlyBreakdown {
        var newExpensesBySubCategory = expensesBySubCategory
        let currentAmount = newExpensesBySubCategory[subCategoryId] ?? 0
        newExpensesBySubCategory[subCategoryId] = currentAmount + amount

        let newTotalExpenses = actualExpenses + amount
        let newActualSavings = actualIncome - newTotalExpenses

        return updated(with: [
            "expensesBySubCategory": newExpensesBySubCategory,
            "actualExpenses": newTotalExpenses,
            "actualSavings": max(newActualSavings, 0)
        ])
    }

    /// Marks the month as completed
    /// - Returns: Updated PlanMonthlyBreakdown instance
    func markAsCompleted() -> PlanMonthlyBreakdown {
        return updated(with: ["isCompleted": true])
    }

    /// Calculates projected values based on current progress
    /// - Parameter dayOfMonth: Current day of the month (1-31)
    /// - Returns: Dictionary with projected values
    func calculateProjections(dayOfMonth: Int) -> [String: Double] {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: monthDate)?.count ?? 30
        let progressRatio = Double(dayOfMonth) / Double(daysInMonth)

        guard progressRatio > 0 && progressRatio <= 1 else {
            return [
                "projectedIncome": actualIncome,
                "projectedExpenses": actualExpenses,
                "projectedSavings": actualSavings
            ]
        }

        let projectedIncome = actualIncome / progressRatio
        let projectedExpenses = actualExpenses / progressRatio
        let projectedSavings = projectedIncome - projectedExpenses

        return [
            "projectedIncome": projectedIncome,
            "projectedExpenses": projectedExpenses,
            "projectedSavings": max(projectedSavings, 0)
        ]
    }

    /// Generates a monthly financial report
    /// - Parameter currency: Currency code for formatting
    /// - Returns: Formatted string report
    func generateMonthlyReport(currency: String = "TRY") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current

        func formatCurrency(_ amount: Double) -> String {
            return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
        }

        let report = """
        \(L("monthly_financial_report")): \(monthName)

        \(L("income_summary")):
        • \(L("planned_income")): \(formatCurrency(plannedIncome))
        • \(L("actual_income")): \(formatCurrency(actualIncome))
        • \(L("income_variance")): \(formatCurrency(incomeVariance))
        • \(L("income_achievement")): \(String(format: "%.1f%%", incomeAchievementPercentage))

        \(L("expenses_summary")):
        • \(L("planned_expenses")): \(formatCurrency(plannedExpenses))
        • \(L("actual_expenses")): \(formatCurrency(actualExpenses))
        • \(L("expense_variance")): \(formatCurrency(expenseVariance))
        • \(L("expense_control")): \(String(format: "%.1f%%", expenseControlPercentage))

        \(L("savings_summary")):
        • \(L("planned_savings")): \(formatCurrency(plannedSavings))
        • \(L("actual_savings")): \(formatCurrency(actualSavings))
        • \(L("savings_variance")): \(formatCurrency(savingsVariance))
        • \(L("savings_rate")): \(String(format: "%.1f%%", savingsRate))

        \(L("financial_health_score")): \(String(format: "%.0f/100", financialHealthScore))
        """

        return report
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(planId)
        hasher.combine(month)
    }

    static func == (lhs: PlanMonthlyBreakdown, rhs: PlanMonthlyBreakdown) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - CategoryMonthlyData

/// Represents monthly data for a specific category within a plan breakdown
struct CategoryMonthlyData: Hashable, Codable {
    var plannedBudget: Double
    var actualExpenses: Double
    var transactionCount: Int
    var averageTransactionAmount: Double
    var notes: String

    init(
        plannedBudget: Double = 0.0,
        actualExpenses: Double = 0.0,
        transactionCount: Int = 0,
        averageTransactionAmount: Double = 0.0,
        notes: String = ""
    ) {
        self.plannedBudget = plannedBudget
        self.actualExpenses = actualExpenses
        self.transactionCount = transactionCount
        self.averageTransactionAmount = averageTransactionAmount
        self.notes = notes
    }

    /// Calculates the expense variance (planned - actual)
    var expenseVariance: Double {
        return plannedBudget - actualExpenses
    }

    /// Calculates the budget utilization percentage
    var budgetUtilization: Double {
        guard plannedBudget > 0 else { return actualExpenses > 0 ? 100 : 0 }
        return (actualExpenses / plannedBudget) * 100
    }

    /// Checks if the category is over budget
    var isOverBudget: Bool {
        return actualExpenses > plannedBudget && plannedBudget > 0
    }

    /// Returns the remaining budget
    var remainingBudget: Double {
        return max(plannedBudget - actualExpenses, 0)
    }

    /// Adds an expense to this category
    /// - Parameter amount: Expense amount
    /// - Returns: Updated CategoryMonthlyData
    func addingExpense(_ amount: Double) -> CategoryMonthlyData {
        let newExpenses = actualExpenses + amount
        let newCount = transactionCount + 1
        let newAverage = newExpenses / Double(newCount)

        return CategoryMonthlyData(
            plannedBudget: plannedBudget,
            actualExpenses: newExpenses,
            transactionCount: newCount,
            averageTransactionAmount: newAverage,
            notes: notes
        )
    }
}

// MARK: - Static Factory Methods

extension PlanMonthlyBreakdown {
    /// Creates a monthly breakdown from a financial plan
    /// - Parameters:
    ///   - plan: The financial plan
    ///   - year: Year for the breakdown
    ///   - month: Month number (1-12)
    /// - Returns: PlanMonthlyBreakdown instance
    static func fromPlan(_ plan: FinancialPlan, year: Int, month: Int) -> PlanMonthlyBreakdown {
        let monthString = String(format: "%04d-%02d", year, month)
        let monthlyIncome = plan.averageMonthlyIncome
        let monthlyBudget = plan.averageMonthlyBudget
        let monthlySavings = plan.targetMonthlySavings

        return PlanMonthlyBreakdown(
            planId: plan.id,
            month: monthString,
            year: year,
            monthNumber: month,
            plannedIncome: monthlyIncome,
            plannedExpenses: monthlyBudget,
            plannedSavings: monthlySavings,
            fixedExpenses: plan.totalFixedExpenses,
            variableExpenses: plan.totalVariableBudget
        )
    }

    /// Creates multiple monthly breakdowns for a plan's duration
    /// - Parameter plan: The financial plan
    /// - Returns: Array of PlanMonthlyBreakdown instances
    static func createBreakdownsForPlan(_ plan: FinancialPlan) -> [PlanMonthlyBreakdown] {
        var breakdowns: [PlanMonthlyBreakdown] = []
        let calendar = Calendar.current

        var currentDate = plan.startDate.startOfMonth
        let endDate = plan.endDate.startOfMonth

        while currentDate <= endDate {
            let year = calendar.component(.year, from: currentDate)
            let month = calendar.component(.month, from: currentDate)

            let breakdown = fromPlan(plan, year: year, month: month)
            breakdowns.append(breakdown)

            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) else { break }
            currentDate = nextMonth
        }

        return breakdowns
    }
}

// MARK: - Array Extensions

extension Array where Element == PlanMonthlyBreakdown {
    /// Filters breakdowns by year
    /// - Parameter year: Year to filter by
    /// - Returns: Array of breakdowns for the specified year
    func breakdowns(for year: Int) -> [PlanMonthlyBreakdown] {
        return filter { $0.year == year }
    }

    /// Filters completed breakdowns
    var completedBreakdowns: [PlanMonthlyBreakdown] {
        return filter { $0.isCompleted }
    }

    /// Filters past month breakdowns
    var pastMonthBreakdowns: [PlanMonthlyBreakdown] {
        return filter { $0.isPastMonth }
    }

    /// Sorts breakdowns chronologically
    var sortedChronologically: [PlanMonthlyBreakdown] {
        return sorted { $0.monthDate < $1.monthDate }
    }

    /// Calculates total actual income across all breakdowns
    var totalActualIncome: Double {
        return reduce(0) { $0 + $1.actualIncome }
    }

    /// Calculates total actual expenses across all breakdowns
    var totalActualExpenses: Double {
        return reduce(0) { $0 + $1.actualExpenses }
    }

    /// Calculates total actual savings across all breakdowns
    var totalActualSavings: Double {
        return reduce(0) { $0 + $1.actualSavings }
    }

    /// Calculates average financial health score
    var averageFinancialHealthScore: Double {
        guard !isEmpty else { return 0 }
        let totalScore = reduce(0) { $0 + $1.financialHealthScore }
        return totalScore / Double(count)
    }

    /// Finds the breakdown with the best financial performance
    var bestPerformingMonth: PlanMonthlyBreakdown? {
        return max(by: { $0.financialHealthScore < $1.financialHealthScore })
    }

    /// Finds the breakdown with the worst financial performance
    var worstPerformingMonth: PlanMonthlyBreakdown? {
        return min(by: { $0.financialHealthScore < $1.financialHealthScore })
    }

    /// Groups breakdowns by year
    var groupedByYear: [Int: [PlanMonthlyBreakdown]] {
        return Dictionary(grouping: self) { $0.year }
    }

    /// Calculates year-over-year growth for income
    /// - Returns: Dictionary with year -> growth percentage
    func yearOverYearIncomeGrowth() -> [Int: Double] {
        let yearlyTotals = groupedByYear.mapValues { breakdowns in
            breakdowns.totalActualIncome
        }

        var growth: [Int: Double] = [:]
        let sortedYears = yearlyTotals.keys.sorted()

        for i in 1..<sortedYears.count {
            let currentYear = sortedYears[i]
            let previousYear = sortedYears[i - 1]

            let currentTotal = yearlyTotals[currentYear] ?? 0
            let previousTotal = yearlyTotals[previousYear] ?? 0

            if previousTotal > 0 {
                growth[currentYear] = ((currentTotal - previousTotal) / previousTotal) * 100
            }
        }

        return growth
    }
}