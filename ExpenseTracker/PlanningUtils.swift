//
//  PlanningUtils.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI

/// Comprehensive utility functions for financial planning
/// Provides date formatting, validation, plan status calculations, and duration options
/// Replaces Kotlin PlanningUtils with Swift-friendly implementations
struct PlanningUtils {

    // MARK: - Date Formatting Functions

    /// Formats a date for display in the user interface
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: The formatting style to use
    /// - Returns: Formatted date string
    static func formatDate(_ date: Date, style: DateDisplayStyle = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        switch style {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .long:
            formatter.dateStyle = .long
        case .full:
            formatter.dateStyle = .full
        case .relative:
            return formatRelativeDate(date)
        case .custom(let format):
            formatter.dateFormat = format
        }

        return formatter.string(from: date)
    }

    /// Formats a date range for display
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    ///   - style: The formatting style to use
    /// - Returns: Formatted date range string
    static func formatDateRange(_ startDate: Date, _ endDate: Date, style: DateDisplayStyle = .medium) -> String {
        let calendar = Calendar.current

        // If same day, just show the date
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return formatDate(startDate, style: style)
        }

        // If same month and year, optimize format
        if calendar.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            let formatter = DateFormatter()
            formatter.locale = Locale.current

            switch style {
            case .short:
                formatter.dateFormat = "MMM d"
                let startString = formatter.string(from: startDate)
                formatter.dateFormat = "d, yyyy"
                let endString = formatter.string(from: endDate)
                return "\(startString) - \(endString)"
            case .medium:
                formatter.dateFormat = "MMM d"
                let startString = formatter.string(from: startDate)
                formatter.dateFormat = "d, yyyy"
                let endString = formatter.string(from: endDate)
                return "\(startString) - \(endString)"
            default:
                return "\(formatDate(startDate, style: style)) - \(formatDate(endDate, style: style))"
            }
        }

        return "\(formatDate(startDate, style: style)) - \(formatDate(endDate, style: style))"
    }

    /// Formats a relative date (e.g., "2 days ago", "in 1 week")
    /// - Parameter date: The date to format
    /// - Returns: Relative date string
    static func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full

        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Formats duration in a human-readable way
    /// - Parameters:
    ///   - startDate: The start date
    ///   - endDate: The end date
    /// - Returns: Human-readable duration string
    static func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: startDate, to: endDate)

        var parts: [String] = []

        if let years = components.year, years > 0 {
            let yearString = years == 1 ? L("duration_year") : L("duration_years")
            parts.append("\(years) \(yearString)")
        }

        if let months = components.month, months > 0 {
            let monthString = months == 1 ? L("duration_month") : L("duration_months")
            parts.append("\(months) \(monthString)")
        }

        if let days = components.day, days > 0, parts.count < 2 {
            let dayString = days == 1 ? L("duration_day") : L("duration_days")
            parts.append("\(days) \(dayString)")
        }

        if parts.isEmpty {
            return L("duration_same_day")
        }

        return parts.joined(separator: ", ")
    }

    /// Gets the month key (YYYY-MM format) for a date
    /// - Parameter date: The date
    /// - Returns: Month key string
    static func getMonthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    /// Gets all month keys between two dates
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of month key strings
    static func getMonthKeys(from startDate: Date, to endDate: Date) -> [String] {
        var monthKeys: [String] = []
        let calendar = Calendar.current
        var currentDate = startDate

        while currentDate <= endDate {
            monthKeys.append(getMonthKey(for: currentDate))

            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }

        return monthKeys
    }

    // MARK: - Validation Functions

    /// Validates if a financial plan is properly configured
    /// - Parameter plan: The financial plan to validate
    /// - Returns: Validation result with any issues found
    static func validateFinancialPlan(_ plan: FinancialPlan) -> ValidationResult {
        var issues: [ValidationIssue] = []

        // Basic plan validation
        if plan.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                type: .missingName,
                severity: .error,
                message: L("validation_missing_plan_name")
            ))
        }

        if plan.startDate >= plan.endDate {
            issues.append(ValidationIssue(
                type: .invalidDateRange,
                severity: .error,
                message: L("validation_invalid_date_range")
            ))
        }

        if plan.totalIncome <= 0 {
            issues.append(ValidationIssue(
                type: .invalidIncome,
                severity: .error,
                message: L("validation_invalid_income")
            ))
        }

        if plan.savingsGoal < 0 {
            issues.append(ValidationIssue(
                type: .invalidSavingsGoal,
                severity: .error,
                message: L("validation_negative_savings_goal")
            ))
        }

        if plan.annualInterestRate < 0 || plan.annualInterestRate > 1 {
            issues.append(ValidationIssue(
                type: .invalidInterestRate,
                severity: .error,
                message: L("validation_invalid_interest_rate")
            ))
        }

        // Budget validation
        let totalMonthlyBudget = plan.fixedExpenses.values.reduce(0, +) +
                                plan.variableExpenseBudgets.values.reduce(0, +) +
                                plan.targetMonthlySavings

        if totalMonthlyBudget > plan.averageMonthlyIncome * 1.05 { // 5% tolerance
            issues.append(ValidationIssue(
                type: .budgetExceedsIncome,
                severity: .error,
                message: L("validation_budget_exceeds_income")
            ))
        }

        // Warning for unrealistic savings rate
        if plan.savingsRate > 50 {
            issues.append(ValidationIssue(
                type: .unrealisticSavingsRate,
                severity: .warning,
                message: L("validation_high_savings_rate")
            ))
        }

        // Warning for insufficient emergency fund
        if plan.emergencyFundGoal < plan.averageMonthlyBudget * 3 {
            issues.append(ValidationIssue(
                type: .insufficientEmergencyFund,
                severity: .warning,
                message: L("validation_low_emergency_fund")
            ))
        }

        return ValidationResult(
            isValid: !issues.contains { $0.severity == .error },
            issues: issues
        )
    }

    /// Validates expense data
    /// - Parameter expense: The expense to validate
    /// - Returns: Validation result
    static func validateExpense(_ expense: Expense) -> ValidationResult {
        var issues: [ValidationIssue] = []

        if expense.amount <= 0 {
            issues.append(ValidationIssue(
                type: .invalidAmount,
                severity: .error,
                message: L("validation_invalid_expense_amount")
            ))
        }

        if expense.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(ValidationIssue(
                type: .missingDescription,
                severity: .error,
                message: L("validation_missing_expense_description")
            ))
        }

        if expense.categoryId.isEmpty {
            issues.append(ValidationIssue(
                type: .missingCategory,
                severity: .error,
                message: L("validation_missing_category")
            ))
        }

        if expense.subCategoryId.isEmpty {
            issues.append(ValidationIssue(
                type: .missingSubCategory,
                severity: .error,
                message: L("validation_missing_subcategory")
            ))
        }

        // Validate recurrence settings
        if expense.recurrenceType != .none {
            if let endDate = expense.recurrenceEndDate, endDate <= expense.date {
                issues.append(ValidationIssue(
                    type: .invalidRecurrenceEndDate,
                    severity: .error,
                    message: L("validation_invalid_recurrence_end_date")
                ))
            }

            if expense.recurrenceType == .custom && expense.customRecurrenceInterval <= 0 {
                issues.append(ValidationIssue(
                    type: .invalidCustomRecurrence,
                    severity: .error,
                    message: L("validation_invalid_custom_recurrence")
                ))
            }
        }

        // Warning for future dates
        if expense.date > Date() {
            issues.append(ValidationIssue(
                type: .futureDate,
                severity: .warning,
                message: L("validation_future_expense_date")
            ))
        }

        return ValidationResult(
            isValid: !issues.contains { $0.severity == .error },
            issues: issues
        )
    }

    /// Validates category budget allocations
    /// - Parameter allocations: Dictionary of category ID to percentage
    /// - Returns: Validation result
    static func validateBudgetAllocations(_ allocations: [String: Double]) -> ValidationResult {
        var issues: [ValidationIssue] = []

        let totalPercentage = allocations.values.reduce(0, +)

        if totalPercentage > 100 {
            issues.append(ValidationIssue(
                type: .budgetExceeds100Percent,
                severity: .error,
                message: L("validation_budget_exceeds_100_percent")
            ))
        }

        if totalPercentage < 95 {
            issues.append(ValidationIssue(
                type: .budgetUnderAllocated,
                severity: .warning,
                message: L("validation_budget_under_allocated")
            ))
        }

        // Check for individual category issues
        for (categoryId, percentage) in allocations {
            if percentage < 0 {
                issues.append(ValidationIssue(
                    type: .negativeAllocation,
                    severity: .error,
                    message: L("validation_negative_category_allocation", categoryId)
                ))
            }

            if percentage > 50 {
                issues.append(ValidationIssue(
                    type: .unrealisticAllocation,
                    severity: .warning,
                    message: L("validation_high_category_allocation", categoryId)
                ))
            }
        }

        return ValidationResult(
            isValid: !issues.contains { $0.severity == .error },
            issues: issues
        )
    }

    // MARK: - Plan Status Calculation

    /// Calculates the current status of a financial plan
    /// - Parameter plan: The financial plan
    /// - Returns: Plan status
    static func calculatePlanStatus(_ plan: FinancialPlan) -> PlanStatus {
        let now = Date()

        if now < plan.startDate {
            return .upcoming
        } else if now > plan.endDate {
            return .completed
        } else if plan.isActive {
            return .active
        } else {
            return .paused
        }
    }

    /// Calculates plan progress as a percentage
    /// - Parameter plan: The financial plan
    /// - Returns: Progress percentage (0-100)
    static func calculatePlanProgress(_ plan: FinancialPlan) -> Double {
        let now = Date()

        if now <= plan.startDate {
            return 0.0
        } else if now >= plan.endDate {
            return 100.0
        }

        let totalDuration = plan.endDate.timeIntervalSince(plan.startDate)
        let elapsedDuration = now.timeIntervalSince(plan.startDate)

        return (elapsedDuration / totalDuration) * 100.0
    }

    /// Gets remaining time for a plan
    /// - Parameter plan: The financial plan
    /// - Returns: Remaining time information
    static func getRemainingTime(for plan: FinancialPlan) -> RemainingTime {
        let now = Date()
        let calendar = Calendar.current

        if now >= plan.endDate {
            return RemainingTime(
                isCompleted: true,
                days: 0,
                months: 0,
                years: 0,
                formattedString: L("plan_completed")
            )
        }

        let components = calendar.dateComponents([.year, .month, .day], from: now, to: plan.endDate)

        let years = components.year ?? 0
        let months = components.month ?? 0
        let days = components.day ?? 0

        return RemainingTime(
            isCompleted: false,
            days: days,
            months: months,
            years: years,
            formattedString: formatDuration(from: now, to: plan.endDate)
        )
    }

    // MARK: - Duration Options

    /// Gets predefined duration options for plan creation
    /// - Returns: Array of duration options
    static func getDurationOptions() -> [DurationOption] {
        return [
            DurationOption(
                id: "3months",
                name: L("duration_3_months"),
                months: 3,
                description: L("duration_3_months_description"),
                isRecommended: false
            ),
            DurationOption(
                id: "6months",
                name: L("duration_6_months"),
                months: 6,
                description: L("duration_6_months_description"),
                isRecommended: true
            ),
            DurationOption(
                id: "1year",
                name: L("duration_1_year"),
                months: 12,
                description: L("duration_1_year_description"),
                isRecommended: true
            ),
            DurationOption(
                id: "2years",
                name: L("duration_2_years"),
                months: 24,
                description: L("duration_2_years_description"),
                isRecommended: false
            ),
            DurationOption(
                id: "3years",
                name: L("duration_3_years"),
                months: 36,
                description: L("duration_3_years_description"),
                isRecommended: false
            ),
            DurationOption(
                id: "5years",
                name: L("duration_5_years"),
                months: 60,
                description: L("duration_5_years_description"),
                isRecommended: true
            ),
            DurationOption(
                id: "10years",
                name: L("duration_10_years"),
                months: 120,
                description: L("duration_10_years_description"),
                isRecommended: false
            )
        ]
    }

    /// Gets savings rate options with recommendations
    /// - Returns: Array of savings rate options
    static func getSavingsRateOptions() -> [SavingsRateOption] {
        return [
            SavingsRateOption(
                percentage: 10,
                name: L("savings_rate_10_percent"),
                description: L("savings_rate_10_percent_description"),
                level: .conservative,
                isRecommended: false
            ),
            SavingsRateOption(
                percentage: 15,
                name: L("savings_rate_15_percent"),
                description: L("savings_rate_15_percent_description"),
                level: .moderate,
                isRecommended: true
            ),
            SavingsRateOption(
                percentage: 20,
                name: L("savings_rate_20_percent"),
                description: L("savings_rate_20_percent_description"),
                level: .moderate,
                isRecommended: true
            ),
            SavingsRateOption(
                percentage: 30,
                name: L("savings_rate_30_percent"),
                description: L("savings_rate_30_percent_description"),
                level: .aggressive,
                isRecommended: false
            ),
            SavingsRateOption(
                percentage: 50,
                name: L("savings_rate_50_percent"),
                description: L("savings_rate_50_percent_description"),
                level: .aggressive,
                isRecommended: false
            )
        ]
    }

    // MARK: - Financial Calculations

    /// Calculates compound interest
    /// - Parameters:
    ///   - principal: Initial amount
    ///   - rate: Annual interest rate (as decimal)
    ///   - time: Time in years
    ///   - compoundingFrequency: Number of times interest is compounded per year
    /// - Returns: Final amount
    static func calculateCompoundInterest(
        principal: Double,
        rate: Double,
        time: Double,
        compoundingFrequency: Int = 12
    ) -> Double {
        let n = Double(compoundingFrequency)
        return principal * pow(1 + (rate / n), n * time)
    }

    /// Calculates simple interest
    /// - Parameters:
    ///   - principal: Initial amount
    ///   - rate: Annual interest rate (as decimal)
    ///   - time: Time in years
    /// - Returns: Final amount
    static func calculateSimpleInterest(principal: Double, rate: Double, time: Double) -> Double {
        return principal * (1 + (rate * time))
    }

    /// Calculates future value of annuity (regular payments)
    /// - Parameters:
    ///   - payment: Regular payment amount
    ///   - rate: Annual interest rate (as decimal)
    ///   - periods: Number of payment periods
    /// - Returns: Future value
    static func calculateFutureValueOfAnnuity(payment: Double, rate: Double, periods: Int) -> Double {
        guard rate > 0 else {
            return payment * Double(periods)
        }

        let monthlyRate = rate / 12
        return payment * ((pow(1 + monthlyRate, Double(periods)) - 1) / monthlyRate)
    }

    /// Calculates present value of annuity
    /// - Parameters:
    ///   - payment: Regular payment amount
    ///   - rate: Annual interest rate (as decimal)
    ///   - periods: Number of payment periods
    /// - Returns: Present value
    static func calculatePresentValueOfAnnuity(payment: Double, rate: Double, periods: Int) -> Double {
        guard rate > 0 else {
            return payment * Double(periods)
        }

        let monthlyRate = rate / 12
        return payment * ((1 - pow(1 + monthlyRate, -Double(periods))) / monthlyRate)
    }

    /// Calculates required monthly payment to reach a goal
    /// - Parameters:
    ///   - futureValue: Target amount
    ///   - rate: Annual interest rate (as decimal)
    ///   - periods: Number of payment periods
    /// - Returns: Required monthly payment
    static func calculateRequiredPayment(futureValue: Double, rate: Double, periods: Int) -> Double {
        guard rate > 0 else {
            return futureValue / Double(periods)
        }

        let monthlyRate = rate / 12
        return futureValue * (monthlyRate / (pow(1 + monthlyRate, Double(periods)) - 1))
    }

    // MARK: - Budget Analysis

    /// Analyzes budget distribution using common budgeting rules
    /// - Parameter allocations: Category allocations as percentages
    /// - Returns: Budget analysis result
    static func analyzeBudgetDistribution(_ allocations: [String: Double]) -> BudgetAnalysis {
        let total = allocations.values.reduce(0, +)

        // Categorize allocations based on common budgeting principles
        var needs: Double = 0
        var wants: Double = 0
        var savings: Double = 0

        // This would be enhanced with actual category mapping
        for (categoryId, percentage) in allocations {
            if isNeedsCategory(categoryId) {
                needs += percentage
            } else if isSavingsCategory(categoryId) {
                savings += percentage
            } else {
                wants += percentage
            }
        }

        let rule50_30_20 = BudgetRule(
            name: L("budget_rule_50_30_20"),
            needsPercentage: 50,
            wantsPercentage: 30,
            savingsPercentage: 20
        )

        let adherence = calculateRuleAdherence(
            needs: needs,
            wants: wants,
            savings: savings,
            rule: rule50_30_20
        )

        return BudgetAnalysis(
            totalAllocated: total,
            needsPercentage: needs,
            wantsPercentage: wants,
            savingsPercentage: savings,
            ruleAdherence: adherence,
            recommendations: generateBudgetRecommendations(needs: needs, wants: wants, savings: savings)
        )
    }

    // MARK: - Date Utilities

    /// Checks if a date is in the current month
    /// - Parameter date: Date to check
    /// - Returns: True if date is in current month
    static func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Checks if a date is in the current year
    /// - Parameter date: Date to check
    /// - Returns: True if date is in current year
    static func isCurrentYear(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .year)
    }

    /// Gets the start of month for a date
    /// - Parameter date: Input date
    /// - Returns: Start of month date
    static func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    /// Gets the end of month for a date
    /// - Parameter date: Input date
    /// - Returns: End of month date
    static func endOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth(for: date)
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? date
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? date
    }

    /// Gets age in years from birth date
    /// - Parameter birthDate: Birth date
    /// - Returns: Age in years
    static func calculateAge(from birthDate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }

    // MARK: - Currency Formatting

    /// Formats an amount as currency string
    /// - Parameters:
    ///   - amount: Amount to format
    ///   - currency: Currency code
    ///   - showDecimals: Whether to show decimal places
    /// - Returns: Formatted currency string
    static func formatCurrency(_ amount: Double, currency: String = "TRY", showDecimals: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current

        if !showDecimals {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    /// Formats a percentage value
    /// - Parameters:
    ///   - value: Value to format (0-100)
    ///   - decimalPlaces: Number of decimal places
    /// - Returns: Formatted percentage string
    static func formatPercentage(_ value: Double, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces

        return formatter.string(from: NSNumber(value: value / 100)) ?? "\(value)%"
    }

    // MARK: - Private Helper Functions

    private static func isNeedsCategory(_ categoryId: String) -> Bool {
        let needsCategories = ["housing", "food", "transportation", "utilities", "health", "insurance"]
        return needsCategories.contains(categoryId.lowercased())
    }

    private static func isSavingsCategory(_ categoryId: String) -> Bool {
        let savingsCategories = ["savings", "investment", "retirement"]
        return savingsCategories.contains(categoryId.lowercased())
    }

    private static func calculateRuleAdherence(
        needs: Double,
        wants: Double,
        savings: Double,
        rule: BudgetRule
    ) -> BudgetRuleAdherence {
        let needsVariance = abs(needs - rule.needsPercentage)
        let wantsVariance = abs(wants - rule.wantsPercentage)
        let savingsVariance = abs(savings - rule.savingsPercentage)

        let averageVariance = (needsVariance + wantsVariance + savingsVariance) / 3

        let adherenceScore = max(0, 100 - averageVariance * 2) // Scale variance to score

        return BudgetRuleAdherence(
            ruleName: rule.name,
            adherenceScore: adherenceScore,
            needsVariance: needsVariance,
            wantsVariance: wantsVariance,
            savingsVariance: savingsVariance
        )
    }

    private static func generateBudgetRecommendations(
        needs: Double,
        wants: Double,
        savings: Double
    ) -> [BudgetRecommendation] {
        var recommendations: [BudgetRecommendation] = []

        if needs > 60 {
            recommendations.append(BudgetRecommendation(
                type: .reduceNeeds,
                message: L("budget_recommendation_reduce_needs"),
                priority: .high
            ))
        }

        if wants > 40 {
            recommendations.append(BudgetRecommendation(
                type: .reduceWants,
                message: L("budget_recommendation_reduce_wants"),
                priority: .medium
            ))
        }

        if savings < 15 {
            recommendations.append(BudgetRecommendation(
                type: .increaseSavings,
                message: L("budget_recommendation_increase_savings"),
                priority: .high
            ))
        }

        return recommendations
    }
}

// MARK: - Supporting Types

/// Date display style options
enum DateDisplayStyle {
    case short
    case medium
    case long
    case full
    case relative
    case custom(String)
}

/// Validation result structure
struct ValidationResult {
    let isValid: Bool
    let issues: [ValidationIssue]

    var hasErrors: Bool {
        return issues.contains { $0.severity == .error }
    }

    var hasWarnings: Bool {
        return issues.contains { $0.severity == .warning }
    }

    var errorMessages: [String] {
        return issues.filter { $0.severity == .error }.map { $0.message }
    }

    var warningMessages: [String] {
        return issues.filter { $0.severity == .warning }.map { $0.message }
    }
}

/// Validation issue structure
struct ValidationIssue {
    let type: ValidationType
    let severity: ValidationSeverity
    let message: String
}

/// Validation types
enum ValidationType {
    case missingName
    case invalidDateRange
    case invalidIncome
    case invalidSavingsGoal
    case invalidInterestRate
    case budgetExceedsIncome
    case unrealisticSavingsRate
    case insufficientEmergencyFund
    case invalidAmount
    case missingDescription
    case missingCategory
    case missingSubCategory
    case invalidRecurrenceEndDate
    case invalidCustomRecurrence
    case futureDate
    case budgetExceeds100Percent
    case budgetUnderAllocated
    case negativeAllocation
    case unrealisticAllocation
}

/// Validation severity levels
enum ValidationSeverity {
    case error
    case warning
    case info
}

/// Plan status enumeration
enum PlanStatus {
    case upcoming
    case active
    case paused
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .upcoming:
            return L("plan_status_upcoming")
        case .active:
            return L("plan_status_active")
        case .paused:
            return L("plan_status_paused")
        case .completed:
            return L("plan_status_completed")
        case .cancelled:
            return L("plan_status_cancelled")
        }
    }

    var color: Color {
        switch self {
        case .upcoming:
            return .blue
        case .active:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .gray
        case .cancelled:
            return .red
        }
    }
}

/// Remaining time information
struct RemainingTime {
    let isCompleted: Bool
    let days: Int
    let months: Int
    let years: Int
    let formattedString: String
}

/// Duration option for plan creation
struct DurationOption: Identifiable, Hashable {
    let id: String
    let name: String
    let months: Int
    let description: String
    let isRecommended: Bool
}

/// Savings rate option
struct SavingsRateOption: Identifiable, Hashable {
    let percentage: Double
    let name: String
    let description: String
    let level: SavingsLevel
    let isRecommended: Bool

    var id: Double { percentage }
}

/// Savings level categories
enum SavingsLevel {
    case conservative
    case moderate
    case aggressive

    var displayName: String {
        switch self {
        case .conservative:
            return L("savings_level_conservative")
        case .moderate:
            return L("savings_level_moderate")
        case .aggressive:
            return L("savings_level_aggressive")
        }
    }

    var color: Color {
        switch self {
        case .conservative:
            return .blue
        case .moderate:
            return .green
        case .aggressive:
            return .red
        }
    }
}

/// Budget analysis result
struct BudgetAnalysis {
    let totalAllocated: Double
    let needsPercentage: Double
    let wantsPercentage: Double
    let savingsPercentage: Double
    let ruleAdherence: BudgetRuleAdherence
    let recommendations: [BudgetRecommendation]
}

/// Budget rule structure
struct BudgetRule {
    let name: String
    let needsPercentage: Double
    let wantsPercentage: Double
    let savingsPercentage: Double
}

/// Budget rule adherence
struct BudgetRuleAdherence {
    let ruleName: String
    let adherenceScore: Double
    let needsVariance: Double
    let wantsVariance: Double
    let savingsVariance: Double

    var adherenceLevel: AdherenceLevel {
        switch adherenceScore {
        case 80...:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .fair
        default:
            return .poor
        }
    }
}

/// Adherence level
enum AdherenceLevel {
    case excellent
    case good
    case fair
    case poor

    var displayName: String {
        switch self {
        case .excellent:
            return L("adherence_excellent")
        case .good:
            return L("adherence_good")
        case .fair:
            return L("adherence_fair")
        case .poor:
            return L("adherence_poor")
        }
    }

    var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
}

/// Budget recommendation
struct BudgetRecommendation {
    let type: BudgetRecommendationType
    let message: String
    let priority: RecommendationPriority
}

/// Budget recommendation types
enum BudgetRecommendationType {
    case reduceNeeds
    case reduceWants
    case increaseSavings
    case rebalanceCategories
}

/// Recommendation priority levels
enum RecommendationPriority {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:
            return L("priority_low")
        case .medium:
            return L("priority_medium")
        case .high:
            return L("priority_high")
        }
    }

    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Extensions

extension Calendar {
    /// Gets the fiscal year for a given date (assuming April-March fiscal year)
    /// - Parameter date: Input date
    /// - Returns: Fiscal year
    func fiscalYear(for date: Date) -> Int {
        let year = component(.year, from: date)
        let month = component(.month, from: date)

        // If month is January, February, or March, fiscal year is the current calendar year
        // If month is April through December, fiscal year is the next calendar year
        return month <= 3 ? year : year + 1
    }

    /// Gets the quarter for a given date
    /// - Parameter date: Input date
    /// - Returns: Quarter number (1-4)
    func quarter(for date: Date) -> Int {
        let month = component(.month, from: date)
        return ((month - 1) / 3) + 1
    }
}

extension Double {
    /// Formats the double as a currency string
    /// - Parameter currency: Currency code
    /// - Returns: Formatted currency string
    func asCurrency(currency: String = "TRY") -> String {
        return PlanningUtils.formatCurrency(self, currency: currency)
    }

    /// Formats the double as a percentage string
    /// - Parameter decimalPlaces: Number of decimal places
    /// - Returns: Formatted percentage string
    func asPercentage(decimalPlaces: Int = 1) -> String {
        return PlanningUtils.formatPercentage(self, decimalPlaces: decimalPlaces)
    }

    /// Rounds to specified decimal places
    /// - Parameter places: Number of decimal places
    /// - Returns: Rounded value
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Date {
    /// Returns the date as a month key string
    var monthKey: String {
        return PlanningUtils.getMonthKey(for: self)
    }

    /// Checks if the date is in the current month
    var isCurrentMonth: Bool {
        return PlanningUtils.isCurrentMonth(self)
    }

    /// Checks if the date is in the current year
    var isCurrentYear: Bool {
        return PlanningUtils.isCurrentYear(self)
    }

    /// Gets the start of month for this date
    var startOfMonth: Date {
        return PlanningUtils.startOfMonth(for: self)
    }

    /// Gets the end of month for this date
    var endOfMonth: Date {
        return PlanningUtils.endOfMonth(for: self)
    }
}