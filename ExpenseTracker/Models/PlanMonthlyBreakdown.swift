//
//  PlanMonthlyBreakdown.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanMonthlyBreakdown.kt
//

import Foundation

struct PlanMonthlyBreakdown: Identifiable, Codable {
    let id: String
    let planId: String
    let monthIndex: Int
    let projectedIncome: Double
    let fixedExpenses: Double
    let averageExpenses: Double
    let totalProjectedExpenses: Double
    let netAmount: Double
    let interestEarned: Double
    let cumulativeNet: Double

    init(id: String = UUID().uuidString, planId: String, monthIndex: Int, projectedIncome: Double, fixedExpenses: Double, averageExpenses: Double, totalProjectedExpenses: Double, netAmount: Double, interestEarned: Double = 0.0, cumulativeNet: Double) {
        self.id = id
        self.planId = planId
        self.monthIndex = monthIndex
        self.projectedIncome = projectedIncome
        self.fixedExpenses = fixedExpenses
        self.averageExpenses = averageExpenses
        self.totalProjectedExpenses = totalProjectedExpenses
        self.netAmount = netAmount
        self.interestEarned = interestEarned
        self.cumulativeNet = cumulativeNet
    }

    func getSavingsRate() -> Float {
        if projectedIncome > 0 {
            return Float(netAmount / projectedIncome)
        } else {
            return 0.0
        }
    }

    func getExpenseRatio() -> Float {
        if projectedIncome > 0 {
            return Float(totalProjectedExpenses / projectedIncome)
        } else {
            return 0.0
        }
    }
}