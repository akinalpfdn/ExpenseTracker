//
//  PlanningUtils.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanningUtils.kt
//

import Foundation
import SwiftUI

struct PlanningUtils {

    // MARK: - Date Formatting

    /**
     * Formats a plan's date range
     */
    static func formatPlanDateRange(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale.current
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /**
     * Gets plan status text
     */
    static func getPlanStatusText(plan: FinancialPlan) -> String {
        let now = Date()
        if now < plan.startDate {
            return "plan_status_not_started".localized
        } else if now > plan.endDate {
            return "plan_status_completed".localized
        } else {
            return "plan_status_active".localized
        }
    }

    /**
     * Gets plan status color based on current state
     */
    static func getPlanStatusColor(plan: FinancialPlan) -> Color {
        let now = Date()
        if now < plan.startDate {
            return Color(red: 0x8E/255.0, green: 0x8E/255.0, blue: 0x93/255.0) // Gray
        } else if now > plan.endDate {
            return Color(red: 0x34/255.0, green: 0xC7/255.0, blue: 0x59/255.0) // Green
        } else {
            return Color(red: 0x00/255.0, green: 0x7A/255.0, blue: 0xFF/255.0) // Blue
        }
    }

    // MARK: - Calculations

    /**
     * Calculates the total projected savings for a plan
     */
    static func calculateTotalProjectedSavings(breakdowns: [PlanMonthlyBreakdown]) -> Double {
        return breakdowns.last?.cumulativeNet ?? 0.0
    }

    /**
     * Gets month name for a given month index from plan start
     */
    static func getMonthName(plan: FinancialPlan, monthIndex: Int) -> String {
        let targetDate = Calendar.current.date(byAdding: .month, value: monthIndex, to: plan.startDate) ?? plan.startDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: targetDate)
    }

    // MARK: - Validation

    /**
     * Validates plan input parameters
     */
    static func validatePlanInput(
        name: String,
        monthlyIncome: Double,
        durationInMonths: Int,
        inflationRate: Double?
    ) -> PlanValidationResult {
        var errors: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("validation_plan_name_empty".localized)
        }

        if monthlyIncome <= 0 {
            errors.append("validation_monthly_income_positive".localized)
        }

        if durationInMonths <= 0 {
            errors.append("validation_duration_positive".localized)
        }

        if durationInMonths > 120 { // 10 years max
            errors.append("validation_duration_max_10_years".localized)
        }

        if let inflationRate = inflationRate, (inflationRate < -50 || inflationRate > 100) {
            errors.append("validation_inflation_rate_range".localized)
        }

        return PlanValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }

    /**
     * Generates suggested plan durations
     */
    static func getSuggestedPlanDurations() -> [PlanDurationOption] {
        return [
            PlanDurationOption(months: 3, displayText: "duration_3_months".localized),
            PlanDurationOption(months: 6, displayText: "duration_6_months".localized),
            PlanDurationOption(months: 12, displayText: "duration_1_year".localized),
            PlanDurationOption(months: 18, displayText: "duration_1_5_years".localized),
            PlanDurationOption(months: 24, displayText: "duration_2_years".localized),
            PlanDurationOption(months: 36, displayText: "duration_3_years".localized),
            PlanDurationOption(months: 60, displayText: "duration_5_years".localized)
        ]
    }
}

// MARK: - Data Structures

struct PlanValidationResult {
    let isValid: Bool
    let errors: [String]
}

struct PlanDurationOption {
    let months: Int
    let displayText: String
}