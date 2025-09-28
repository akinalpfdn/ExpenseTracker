//
//  FinancialPlan.swift
//  ExpenseTracker
//
//  Created by migration from Android FinancialPlan.kt
//

import Foundation
import CoreData

struct FinancialPlan: Identifiable, Codable {
    let id: String
    let name: String
    let startDate: Date
    let durationInMonths: Int
    let monthlyIncome: Double
    let manualMonthlyExpenses: Double
    let useAppExpenseData: Bool
    let isInflationApplied: Bool
    let inflationRate: Double
    let isInterestApplied: Bool
    let interestRate: Double
    let interestType: InterestType
    let createdAt: Date
    let updatedAt: Date
    let defaultCurrency: String

    init(id: String = UUID().uuidString, name: String, startDate: Date, durationInMonths: Int, monthlyIncome: Double, manualMonthlyExpenses: Double = 0.0, useAppExpenseData: Bool = true, isInflationApplied: Bool = false, inflationRate: Double = 0.0, isInterestApplied: Bool = false, interestRate: Double = 0.0, interestType: InterestType = .compound, createdAt: Date = Date(), updatedAt: Date = Date(), defaultCurrency: String) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.durationInMonths = durationInMonths
        self.monthlyIncome = monthlyIncome
        self.manualMonthlyExpenses = manualMonthlyExpenses
        self.useAppExpenseData = useAppExpenseData
        self.isInflationApplied = isInflationApplied
        self.inflationRate = inflationRate
        self.isInterestApplied = isInterestApplied
        self.interestRate = interestRate
        self.interestType = interestType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.defaultCurrency = defaultCurrency
    }

    var endDate: Date {
        return Calendar.current.date(byAdding: .month, value: durationInMonths, to: startDate) ?? startDate
    }

    func getMonthlyIncomeAtMonth(monthIndex: Int) -> Double {
        return monthlyIncome
    }

    func getTotalExpectedIncome() -> Double {
        if isInflationApplied && inflationRate > 0 {
            var total = 0.0
            for month in 0..<durationInMonths {
                total += getMonthlyIncomeAtMonth(monthIndex: month)
            }
            return total
        } else {
            return monthlyIncome * Double(durationInMonths)
        }
    }

    func isActive() -> Bool {
        let now = Date()
        return now > startDate && now < endDate
    }

    func getMonthsElapsed() -> Int {
        let now = Date()
        let calendar = Calendar.current

        if now < startDate {
            return 0
        } else if now > endDate {
            return durationInMonths
        } else {
            let components = calendar.dateComponents([.month], from: startDate, to: now)
            return (components.month ?? 0) + 1
        }
    }

    func getProgressPercentage() -> Float {
        let elapsed = getMonthsElapsed()
        return Float(elapsed) / Float(durationInMonths)
    }
}

// MARK: - Core Data Conversion
extension FinancialPlan {
    init(from entity: FinancialPlanEntity) {
        self.id = entity.id ?? ""
        self.name = entity.name ?? ""
        self.startDate = entity.startDate ?? Date()
        self.durationInMonths = Int(entity.durationInMonths)
        self.monthlyIncome = entity.monthlyIncome
        self.manualMonthlyExpenses = entity.manualMonthlyExpenses
        self.useAppExpenseData = entity.useAppExpenseData
        self.isInflationApplied = entity.isInflationApplied
        self.inflationRate = entity.inflationRate
        self.isInterestApplied = entity.isInterestApplied
        self.interestRate = entity.interestRate
        self.interestType = InterestType(rawValue: entity.interestType ?? "COMPOUND") ?? .compound
        self.createdAt = entity.createdAt ?? Date()
        self.updatedAt = entity.updatedAt ?? Date()
        self.defaultCurrency = entity.defaultCurrency ?? ""
    }

    func toCoreData(context: NSManagedObjectContext) -> FinancialPlanEntity {
        let entity = FinancialPlanEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.startDate = self.startDate
        entity.durationInMonths = Int32(self.durationInMonths)
        entity.monthlyIncome = self.monthlyIncome
        entity.manualMonthlyExpenses = self.manualMonthlyExpenses
        entity.useAppExpenseData = self.useAppExpenseData
        entity.isInflationApplied = self.isInflationApplied
        entity.inflationRate = self.inflationRate
        entity.isInterestApplied = self.isInterestApplied
        entity.interestRate = self.interestRate
        entity.interestType = self.interestType.rawValue
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
        entity.defaultCurrency = self.defaultCurrency
        return entity
    }
}