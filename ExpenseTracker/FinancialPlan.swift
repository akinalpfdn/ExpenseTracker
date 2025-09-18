//
//  FinancialPlan.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI

/// Represents a comprehensive financial plan with calculation methods and goal tracking
/// Replaces Kotlin FinancialPlan entity with Swift-friendly implementation
struct FinancialPlan: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var description: String
    var startDate: Date
    var endDate: Date
    var totalIncome: Double
    var totalBudget: Double
    var savingsGoal: Double
    var emergencyFundGoal: Double
    var interestType: InterestType
    var annualInterestRate: Double
    var compoundingFrequency: Int
    var isActive: Bool
    var currency: String
    var createdAt: Date
    var updatedAt: Date
    var categoryAllocations: [String: Double] // categoryId -> allocated amount
    var monthlyIncomeBreakdown: [String: Double] // month -> income
    var fixedExpenses: [String: Double] // description -> amount
    var variableExpenseBudgets: [String: Double] // categoryId -> budget
    var savingsContributions: [String: Double] // month -> contribution
    var actualExpenses: [String: Double] // month -> total expenses
    var notes: String
    var tags: [String]

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        startDate: Date,
        endDate: Date,
        totalIncome: Double = 0.0,
        totalBudget: Double = 0.0,
        savingsGoal: Double = 0.0,
        emergencyFundGoal: Double = 0.0,
        interestType: InterestType = .compound,
        annualInterestRate: Double = 0.05,
        compoundingFrequency: Int = 12,
        isActive: Bool = true,
        currency: String = "TRY",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        categoryAllocations: [String: Double] = [:],
        monthlyIncomeBreakdown: [String: Double] = [:],
        fixedExpenses: [String: Double] = [:],
        variableExpenseBudgets: [String: Double] = [:],
        savingsContributions: [String: Double] = [:],
        actualExpenses: [String: Double] = [:],
        notes: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.totalIncome = totalIncome
        self.totalBudget = totalBudget
        self.savingsGoal = savingsGoal
        self.emergencyFundGoal = emergencyFundGoal
        self.interestType = interestType
        self.annualInterestRate = annualInterestRate
        self.compoundingFrequency = compoundingFrequency
        self.isActive = isActive
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.categoryAllocations = categoryAllocations
        self.monthlyIncomeBreakdown = monthlyIncomeBreakdown
        self.fixedExpenses = fixedExpenses
        self.variableExpenseBudgets = variableExpenseBudgets
        self.savingsContributions = savingsContributions
        self.actualExpenses = actualExpenses
        self.notes = notes
        self.tags = tags
    }

    // MARK: - Computed Properties

    /// Returns the duration of the plan in years
    var durationInYears: Double {
        let timeInterval = endDate.timeIntervalSince(startDate)
        return timeInterval / (365.25 * 24 * 60 * 60) // Account for leap years
    }

    /// Returns the duration of the plan in months
    var durationInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return components.month ?? 0
    }

    /// Returns the average monthly income
    var averageMonthlyIncome: Double {
        guard durationInMonths > 0 else { return 0 }
        return totalIncome / Double(durationInMonths)
    }

    /// Returns the average monthly budget
    var averageMonthlyBudget: Double {
        guard durationInMonths > 0 else { return 0 }
        return totalBudget / Double(durationInMonths)
    }

    /// Returns the target monthly savings
    var targetMonthlySavings: Double {
        guard durationInMonths > 0 else { return 0 }
        return savingsGoal / Double(durationInMonths)
    }

    /// Returns the total fixed expenses per month
    var totalFixedExpenses: Double {
        return fixedExpenses.values.reduce(0, +)
    }

    /// Returns the total variable budget
    var totalVariableBudget: Double {
        return variableExpenseBudgets.values.reduce(0, +)
    }

    /// Returns the available income after fixed expenses
    var availableIncome: Double {
        return averageMonthlyIncome - totalFixedExpenses
    }

    /// Returns the savings rate as a percentage
    var savingsRate: Double {
        guard averageMonthlyIncome > 0 else { return 0 }
        return (targetMonthlySavings / averageMonthlyIncome) * 100
    }

    /// Checks if the plan is currently active (within date range)
    var isCurrentlyActive: Bool {
        let now = Date()
        return isActive && startDate <= now && now <= endDate
    }

    /// Returns the progress percentage of the plan (0-100)
    var progressPercentage: Double {
        let now = Date()
        guard startDate <= now && now <= endDate else {
            return now < startDate ? 0 : 100
        }

        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsedDuration = now.timeIntervalSince(startDate)
        return (elapsedDuration / totalDuration) * 100
    }

    /// Returns formatted currency string for amounts
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    // MARK: - Financial Calculation Methods

    /// Calculates the future value of savings with compound interest
    /// - Parameters:
    ///   - principal: Initial savings amount
    ///   - monthlyContribution: Monthly savings contribution
    ///   - timeInYears: Time period in years
    /// - Returns: Future value of savings
    func calculateFutureValueOfSavings(
        principal: Double = 0,
        monthlyContribution: Double? = nil,
        timeInYears: Double? = nil
    ) -> Double {
        let contribution = monthlyContribution ?? targetMonthlySavings
        let time = timeInYears ?? durationInYears

        // Future value of principal
        let principalFV = interestType.calculateAmount(
            principal: principal,
            rate: annualInterestRate,
            time: time,
            compoundingFrequency: compoundingFrequency
        )

        // Future value of annuity (monthly contributions)
        guard contribution > 0 && annualInterestRate > 0 else {
            return principalFV + (contribution * 12 * time)
        }

        let monthlyRate = annualInterestRate / 12
        let totalMonths = time * 12
        let annuityFV = contribution * ((pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate)

        return principalFV + annuityFV
    }

    /// Calculates the required monthly savings to reach the savings goal
    /// - Returns: Required monthly savings amount
    func calculateRequiredMonthlySavings() -> Double {
        guard durationInYears > 0 && annualInterestRate > 0 else {
            return savingsGoal / max(Double(durationInMonths), 1)
        }

        let monthlyRate = annualInterestRate / 12
        let totalMonths = durationInYears * 12

        // PMT calculation: A = P * (r * (1 + r)^n) / ((1 + r)^n - 1)
        let factor = (pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate
        return savingsGoal / factor
    }

    /// Calculates the emergency fund progress
    /// - Parameter currentEmergencyFund: Current emergency fund amount
    /// - Returns: Progress percentage and remaining amount needed
    func calculateEmergencyFundProgress(currentAmount: Double) -> (percentage: Double, remaining: Double) {
        guard emergencyFundGoal > 0 else { return (0, 0) }

        let percentage = min((currentAmount / emergencyFundGoal) * 100, 100)
        let remaining = max(emergencyFundGoal - currentAmount, 0)

        return (percentage, remaining)
    }

    /// Calculates the debt payoff schedule
    /// - Parameters:
    ///   - debtAmount: Total debt amount
    ///   - monthlyPayment: Monthly payment amount
    ///   - interestRate: Annual interest rate for debt
    /// - Returns: Number of months to pay off and total interest paid
    func calculateDebtPayoff(
        debtAmount: Double,
        monthlyPayment: Double,
        interestRate: Double
    ) -> (months: Int, totalInterest: Double) {
        guard debtAmount > 0 && monthlyPayment > 0 && interestRate > 0 else {
            return (Int(ceil(debtAmount / monthlyPayment)), 0)
        }

        let monthlyRate = interestRate / 12
        var balance = debtAmount
        var months = 0
        var totalInterest = 0.0

        while balance > 0.01 && months < 1000 { // Safety limit
            let interestPayment = balance * monthlyRate
            let principalPayment = min(monthlyPayment - interestPayment, balance)

            guard principalPayment > 0 else { break } // Payment too low to cover interest

            totalInterest += interestPayment
            balance -= principalPayment
            months += 1
        }

        return (months, totalInterest)
    }

    /// Calculates budget variance analysis
    /// - Parameter actualExpenses: Dictionary of actual expenses by category
    /// - Returns: Variance analysis results
    func calculateBudgetVariance(actualExpenses: [String: Double]) -> [String: Double] {
        var variance: [String: Double] = [:]

        for (categoryId, budgetedAmount) in variableExpenseBudgets {
            let actualAmount = actualExpenses[categoryId] ?? 0
            variance[categoryId] = budgetedAmount - actualAmount
        }

        return variance
    }

    /// Calculates the recommended budget allocation based on the 50/30/20 rule
    /// - Returns: Dictionary with recommended allocations
    func calculateRecommendedBudgetAllocation() -> [String: Double] {
        let monthlyIncome = averageMonthlyIncome

        return [
            "needs": monthlyIncome * 0.50,      // 50% for needs
            "wants": monthlyIncome * 0.30,      // 30% for wants
            "savings": monthlyIncome * 0.20     // 20% for savings and debt repayment
        ]
    }

    /// Calculates the net worth projection over time
    /// - Parameters:
    ///   - currentNetWorth: Current net worth
    ///   - monthlyNetIncome: Monthly net income after expenses
    /// - Returns: Array of net worth projections by month
    func calculateNetWorthProjection(
        currentNetWorth: Double,
        monthlyNetIncome: Double
    ) -> [Double] {
        var projections: [Double] = [currentNetWorth]
        var currentValue = currentNetWorth

        for _ in 1...durationInMonths {
            // Add monthly net income
            currentValue += monthlyNetIncome

            // Apply investment growth (simplified)
            currentValue *= (1 + (annualInterestRate / 12))

            projections.append(currentValue)
        }

        return projections
    }

    // MARK: - Plan Management Methods

    /// Creates a copy of the plan with updated properties
    /// - Parameter updates: Dictionary of property updates
    /// - Returns: New FinancialPlan instance with updated properties
    func updated(with updates: [String: Any]) -> FinancialPlan {
        return FinancialPlan(
            id: self.id,
            name: updates["name"] as? String ?? self.name,
            description: updates["description"] as? String ?? self.description,
            startDate: updates["startDate"] as? Date ?? self.startDate,
            endDate: updates["endDate"] as? Date ?? self.endDate,
            totalIncome: updates["totalIncome"] as? Double ?? self.totalIncome,
            totalBudget: updates["totalBudget"] as? Double ?? self.totalBudget,
            savingsGoal: updates["savingsGoal"] as? Double ?? self.savingsGoal,
            emergencyFundGoal: updates["emergencyFundGoal"] as? Double ?? self.emergencyFundGoal,
            interestType: updates["interestType"] as? InterestType ?? self.interestType,
            annualInterestRate: updates["annualInterestRate"] as? Double ?? self.annualInterestRate,
            compoundingFrequency: updates["compoundingFrequency"] as? Int ?? self.compoundingFrequency,
            isActive: updates["isActive"] as? Bool ?? self.isActive,
            currency: updates["currency"] as? String ?? self.currency,
            createdAt: self.createdAt,
            updatedAt: Date(),
            categoryAllocations: updates["categoryAllocations"] as? [String: Double] ?? self.categoryAllocations,
            monthlyIncomeBreakdown: updates["monthlyIncomeBreakdown"] as? [String: Double] ?? self.monthlyIncomeBreakdown,
            fixedExpenses: updates["fixedExpenses"] as? [String: Double] ?? self.fixedExpenses,
            variableExpenseBudgets: updates["variableExpenseBudgets"] as? [String: Double] ?? self.variableExpenseBudgets,
            savingsContributions: updates["savingsContributions"] as? [String: Double] ?? self.savingsContributions,
            actualExpenses: updates["actualExpenses"] as? [String: Double] ?? self.actualExpenses,
            notes: updates["notes"] as? String ?? self.notes,
            tags: updates["tags"] as? [String] ?? self.tags
        )
    }

    /// Adds a fixed expense to the plan
    /// - Parameters:
    ///   - description: Description of the expense
    ///   - amount: Monthly amount
    /// - Returns: Updated FinancialPlan instance
    func addingFixedExpense(description: String, amount: Double) -> FinancialPlan {
        var newFixedExpenses = fixedExpenses
        newFixedExpenses[description] = amount
        return updated(with: ["fixedExpenses": newFixedExpenses])
    }

    /// Removes a fixed expense from the plan
    /// - Parameter description: Description of the expense to remove
    /// - Returns: Updated FinancialPlan instance
    func removingFixedExpense(description: String) -> FinancialPlan {
        var newFixedExpenses = fixedExpenses
        newFixedExpenses.removeValue(forKey: description)
        return updated(with: ["fixedExpenses": newFixedExpenses])
    }

    /// Updates the budget for a category
    /// - Parameters:
    ///   - categoryId: Category identifier
    ///   - budget: New budget amount
    /// - Returns: Updated FinancialPlan instance
    func updatingCategoryBudget(categoryId: String, budget: Double) -> FinancialPlan {
        var newBudgets = variableExpenseBudgets
        newBudgets[categoryId] = budget
        return updated(with: ["variableExpenseBudgets": newBudgets])
    }

    /// Records actual expenses for a month
    /// - Parameters:
    ///   - month: Month identifier (YYYY-MM format)
    ///   - amount: Total expenses for the month
    /// - Returns: Updated FinancialPlan instance
    func recordingActualExpenses(month: String, amount: Double) -> FinancialPlan {
        var newActualExpenses = actualExpenses
        newActualExpenses[month] = amount
        return updated(with: ["actualExpenses": newActualExpenses])
    }

    /// Generates a comprehensive financial report
    /// - Returns: Formatted string report
    func generateFinancialReport() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current

        let report = """
        \(L("financial_plan_report")): \(name)

        \(L("plan_duration")): \(DateConverters.dateToDisplayString(startDate)) - \(DateConverters.dateToDisplayString(endDate))
        \(L("plan_progress")): \(String(format: "%.1f%%", progressPercentage))

        \(L("income_and_budget")):
        • \(L("total_income")): \(formatCurrency(totalIncome))
        • \(L("monthly_income")): \(formatCurrency(averageMonthlyIncome))
        • \(L("total_budget")): \(formatCurrency(totalBudget))
        • \(L("monthly_budget")): \(formatCurrency(averageMonthlyBudget))

        \(L("savings_goals")):
        • \(L("savings_goal")): \(formatCurrency(savingsGoal))
        • \(L("monthly_savings_target")): \(formatCurrency(targetMonthlySavings))
        • \(L("savings_rate")): \(String(format: "%.1f%%", savingsRate))
        • \(L("emergency_fund_goal")): \(formatCurrency(emergencyFundGoal))

        \(L("expenses_breakdown")):
        • \(L("fixed_expenses")): \(formatCurrency(totalFixedExpenses))
        • \(L("variable_budget")): \(formatCurrency(totalVariableBudget))
        • \(L("available_income")): \(formatCurrency(availableIncome))

        \(L("investment_details")):
        • \(L("interest_type")): \(interestType.displayName)
        • \(L("annual_rate")): \(String(format: "%.2f%%", annualInterestRate * 100))
        • \(L("compounding_frequency")): \(compoundingFrequency) \(L("times_per_year"))
        """

        return report
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(startDate)
        hasher.combine(endDate)
    }

    static func == (lhs: FinancialPlan, rhs: FinancialPlan) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - FinancialPlan Extensions

extension FinancialPlan {
    /// Creates a basic financial plan template
    /// - Parameters:
    ///   - name: Plan name
    ///   - monthlyIncome: Monthly income amount
    ///   - startDate: Plan start date
    ///   - durationMonths: Plan duration in months
    /// - Returns: Basic FinancialPlan instance
    static func basicPlan(
        name: String,
        monthlyIncome: Double,
        startDate: Date = Date(),
        durationMonths: Int = 12
    ) -> FinancialPlan {
        let endDate = Calendar.current.date(byAdding: .month, value: durationMonths, to: startDate) ?? startDate
        let totalIncome = monthlyIncome * Double(durationMonths)

        return FinancialPlan(
            name: name,
            description: L("basic_financial_plan_description"),
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            totalBudget: totalIncome * 0.8, // 80% for expenses
            savingsGoal: totalIncome * 0.2, // 20% for savings
            emergencyFundGoal: monthlyIncome * 6, // 6 months emergency fund
            interestType: .compound,
            annualInterestRate: 0.05, // 5% annual return
            compoundingFrequency: 12
        )
    }

    /// Creates an aggressive savings plan
    /// - Parameters:
    ///   - name: Plan name
    ///   - monthlyIncome: Monthly income amount
    ///   - savingsRate: Savings rate (0.0 to 1.0)
    ///   - startDate: Plan start date
    ///   - durationMonths: Plan duration in months
    /// - Returns: Aggressive savings FinancialPlan instance
    static func aggressiveSavingsPlan(
        name: String,
        monthlyIncome: Double,
        savingsRate: Double = 0.5,
        startDate: Date = Date(),
        durationMonths: Int = 60
    ) -> FinancialPlan {
        let endDate = Calendar.current.date(byAdding: .month, value: durationMonths, to: startDate) ?? startDate
        let totalIncome = monthlyIncome * Double(durationMonths)
        let monthlySavings = monthlyIncome * savingsRate

        return FinancialPlan(
            name: name,
            description: L("aggressive_savings_plan_description"),
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            totalBudget: totalIncome * (1 - savingsRate),
            savingsGoal: monthlySavings * Double(durationMonths),
            emergencyFundGoal: monthlyIncome * 12, // 12 months emergency fund
            interestType: .compound,
            annualInterestRate: 0.07, // 7% annual return
            compoundingFrequency: 12
        )
    }

    /// Creates a debt payoff plan
    /// - Parameters:
    ///   - name: Plan name
    ///   - monthlyIncome: Monthly income amount
    ///   - totalDebt: Total debt amount
    ///   - debtPaymentPercentage: Percentage of income for debt payment
    ///   - startDate: Plan start date
    /// - Returns: Debt payoff FinancialPlan instance
    static func debtPayoffPlan(
        name: String,
        monthlyIncome: Double,
        totalDebt: Double,
        debtPaymentPercentage: Double = 0.3,
        startDate: Date = Date()
    ) -> FinancialPlan {
        let monthlyDebtPayment = monthlyIncome * debtPaymentPercentage
        let estimatedMonths = Int(ceil(totalDebt / monthlyDebtPayment))
        let endDate = Calendar.current.date(byAdding: .month, value: estimatedMonths, to: startDate) ?? startDate
        let totalIncome = monthlyIncome * Double(estimatedMonths)

        return FinancialPlan(
            name: name,
            description: L("debt_payoff_plan_description"),
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            totalBudget: totalIncome * 0.7, // 70% for expenses (30% for debt)
            savingsGoal: 0, // Focus on debt first
            emergencyFundGoal: monthlyIncome * 3, // Minimal emergency fund
            interestType: .simple,
            annualInterestRate: 0.03, // Conservative savings rate
            compoundingFrequency: 12
        )
    }
}

// MARK: - Array Extensions for FinancialPlan Management

extension Array where Element == FinancialPlan {
    /// Filters active plans
    var activePlans: [FinancialPlan] {
        return filter { $0.isActive }
    }

    /// Filters currently active plans (within date range)
    var currentlyActivePlans: [FinancialPlan] {
        return filter { $0.isCurrentlyActive }
    }

    /// Sorts plans by start date
    var sortedByStartDate: [FinancialPlan] {
        return sorted { $0.startDate < $1.startDate }
    }

    /// Finds plan by name
    /// - Parameter name: Plan name to search for
    /// - Returns: FinancialPlan if found, nil otherwise
    func plan(named name: String) -> FinancialPlan? {
        return first { $0.name == name }
    }

    /// Calculates total savings goal across all plans
    var totalSavingsGoal: Double {
        return reduce(0) { $0 + $1.savingsGoal }
    }

    /// Calculates total income across all plans
    var totalIncome: Double {
        return reduce(0) { $0 + $1.totalIncome }
    }
}