//
//  PlanMonthlyBreakdown.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanMonthlyBreakdown.kt
//

import Foundation
import CoreData

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

// MARK: - Core Data Conversion
extension PlanMonthlyBreakdown {
    init(from entity: PlanMonthlyBreakdownEntity) {
        self.id = entity.id ?? ""
        self.planId = entity.planId ?? ""
        self.monthIndex = Int(entity.monthIndex)
        self.projectedIncome = entity.projectedIncome
        self.fixedExpenses = entity.fixedExpenses
        self.averageExpenses = entity.averageExpenses
        self.totalProjectedExpenses = entity.totalProjectedExpenses
        self.netAmount = entity.netAmount
        self.interestEarned = entity.interestEarned
        self.cumulativeNet = entity.cumulativeNet
    }

    func toCoreData(context: NSManagedObjectContext) -> PlanMonthlyBreakdownEntity {
        let entity = PlanMonthlyBreakdownEntity(context: context)
        entity.id = self.id
        entity.planId = self.planId
        entity.monthIndex = Int32(self.monthIndex)
        entity.projectedIncome = self.projectedIncome
        entity.fixedExpenses = self.fixedExpenses
        entity.averageExpenses = self.averageExpenses
        entity.totalProjectedExpenses = self.totalProjectedExpenses
        entity.netAmount = self.netAmount
        entity.interestEarned = self.interestEarned
        entity.cumulativeNet = self.cumulativeNet
        return entity
    }
}