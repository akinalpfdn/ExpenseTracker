//
//  InterestType.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation

/// Represents the different types of interest calculations available in financial planning
/// Used for compound and simple interest calculations in financial plans
enum InterestType: String, CaseIterable, Identifiable, Hashable, Codable {
    case simple = "SIMPLE"
    case compound = "COMPOUND"

    var id: String { rawValue }

    /// Localized display name for the interest type
    var displayName: String {
        switch self {
        case .simple:
            return L("interest_type_simple")
        case .compound:
            return L("interest_type_compound")
        }
    }

    /// Detailed description of the interest type
    var description: String {
        switch self {
        case .simple:
            return L("interest_type_simple_description")
        case .compound:
            return L("interest_type_compound_description")
        }
    }

    /// SF Symbol icon representing the interest type
    var iconName: String {
        switch self {
        case .simple:
            return "chart.line.uptrend.xyaxis"
        case .compound:
            return "chart.line.uptrend.xyaxis.circle.fill"
        }
    }

    /// Calculates interest based on the type
    /// - Parameters:
    ///   - principal: The initial amount of money
    ///   - rate: The annual interest rate as a decimal (e.g., 0.05 for 5%)
    ///   - time: The time period in years
    ///   - compoundingFrequency: How many times per year interest is compounded (only used for compound interest)
    /// - Returns: The total amount including interest
    func calculateAmount(principal: Double, rate: Double, time: Double, compoundingFrequency: Int = 1) -> Double {
        switch self {
        case .simple:
            // Simple Interest: A = P(1 + rt)
            return principal * (1 + rate * time)
        case .compound:
            // Compound Interest: A = P(1 + r/n)^(nt)
            let ratePerPeriod = rate / Double(compoundingFrequency)
            let numberOfPeriods = Double(compoundingFrequency) * time
            return principal * pow(1 + ratePerPeriod, numberOfPeriods)
        }
    }

    /// Calculates only the interest earned (not including principal)
    /// - Parameters:
    ///   - principal: The initial amount of money
    ///   - rate: The annual interest rate as a decimal (e.g., 0.05 for 5%)
    ///   - time: The time period in years
    ///   - compoundingFrequency: How many times per year interest is compounded (only used for compound interest)
    /// - Returns: The interest earned
    func calculateInterest(principal: Double, rate: Double, time: Double, compoundingFrequency: Int = 1) -> Double {
        let totalAmount = calculateAmount(principal: principal, rate: rate, time: time, compoundingFrequency: compoundingFrequency)
        return totalAmount - principal
    }
}