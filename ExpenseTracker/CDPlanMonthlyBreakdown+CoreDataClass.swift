//
//  CDPlanMonthlyBreakdown+CoreDataClass.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

@objc(CDPlanMonthlyBreakdown)
public class CDPlanMonthlyBreakdown: NSManagedObject {

    /// Converts Core Data entity to Swift model
    func toPlanMonthlyBreakdown() -> PlanMonthlyBreakdown {
        let categoryBreakdownDict = parseCategoryBreakdown(from: categoryBreakdown)
        let expensesBySubCategoryDict = parseDictionary(from: expensesBySubCategory)

        return PlanMonthlyBreakdown(
            id: id ?? UUID().uuidString,
            planId: planId ?? "",
            month: month ?? "",
            year: Int(year),
            monthNumber: Int(monthNumber),
            plannedIncome: plannedIncome,
            actualIncome: actualIncome,
            plannedExpenses: plannedExpenses,
            actualExpenses: actualExpenses,
            plannedSavings: plannedSavings,
            actualSavings: actualSavings,
            fixedExpenses: fixedExpenses,
            variableExpenses: variableExpenses,
            emergencyFundContribution: emergencyFundContribution,
            investmentContribution: investmentContribution,
            debtPayment: debtPayment,
            categoryBreakdown: categoryBreakdownDict,
            expensesBySubCategory: expensesBySubCategoryDict,
            notes: notes ?? "",
            isCompleted: isCompleted,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    /// Updates Core Data entity from Swift model
    func update(from breakdown: PlanMonthlyBreakdown) {
        id = breakdown.id
        planId = breakdown.planId
        month = breakdown.month
        year = Int32(breakdown.year)
        monthNumber = Int32(breakdown.monthNumber)
        plannedIncome = breakdown.plannedIncome
        actualIncome = breakdown.actualIncome
        plannedExpenses = breakdown.plannedExpenses
        actualExpenses = breakdown.actualExpenses
        plannedSavings = breakdown.plannedSavings
        actualSavings = breakdown.actualSavings
        fixedExpenses = breakdown.fixedExpenses
        variableExpenses = breakdown.variableExpenses
        emergencyFundContribution = breakdown.emergencyFundContribution
        investmentContribution = breakdown.investmentContribution
        debtPayment = breakdown.debtPayment
        categoryBreakdown = encodeCategoryBreakdown(breakdown.categoryBreakdown)
        expensesBySubCategory = encodeDictionary(breakdown.expensesBySubCategory)
        notes = breakdown.notes
        isCompleted = breakdown.isCompleted
        createdAt = breakdown.createdAt
        updatedAt = breakdown.updatedAt
    }

    /// Creates a new CDPlanMonthlyBreakdown from a PlanMonthlyBreakdown model
    /// - Parameters:
    ///   - breakdown: The PlanMonthlyBreakdown model
    ///   - context: The managed object context
    /// - Returns: New CDPlanMonthlyBreakdown instance
    static func from(_ breakdown: PlanMonthlyBreakdown, context: NSManagedObjectContext) -> CDPlanMonthlyBreakdown {
        let cdBreakdown = CDPlanMonthlyBreakdown(context: context)
        cdBreakdown.update(from: breakdown)
        return cdBreakdown
    }

    // MARK: - Private Helpers

    private func parseDictionary(from string: String?) -> [String: Double] {
        guard let string = string, !string.isEmpty else { return [:] }

        do {
            let data = string.data(using: .utf8) ?? Data()
            let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            return dictionary.compactMapValues { $0 as? Double }
        } catch {
            print("Failed to parse dictionary from string: \(error)")
            return [:]
        }
    }

    private func encodeDictionary(_ dictionary: [String: Double]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to encode dictionary to string: \(error)")
            return ""
        }
    }

    private func parseCategoryBreakdown(from string: String?) -> [String: CategoryMonthlyData] {
        guard let string = string, !string.isEmpty else { return [:] }

        do {
            let data = string.data(using: .utf8) ?? Data()
            let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String: Any]] ?? [:]

            var result: [String: CategoryMonthlyData] = [:]
            for (key, value) in jsonData {
                let plannedBudget = value["plannedBudget"] as? Double ?? 0.0
                let actualExpenses = value["actualExpenses"] as? Double ?? 0.0
                let transactionCount = value["transactionCount"] as? Int ?? 0
                let averageTransactionAmount = value["averageTransactionAmount"] as? Double ?? 0.0
                let notes = value["notes"] as? String ?? ""

                result[key] = CategoryMonthlyData(
                    plannedBudget: plannedBudget,
                    actualExpenses: actualExpenses,
                    transactionCount: transactionCount,
                    averageTransactionAmount: averageTransactionAmount,
                    notes: notes
                )
            }
            return result
        } catch {
            print("Failed to parse category breakdown from string: \(error)")
            return [:]
        }
    }

    private func encodeCategoryBreakdown(_ breakdown: [String: CategoryMonthlyData]) -> String {
        do {
            var jsonData: [String: [String: Any]] = [:]
            for (key, value) in breakdown {
                jsonData[key] = [
                    "plannedBudget": value.plannedBudget,
                    "actualExpenses": value.actualExpenses,
                    "transactionCount": value.transactionCount,
                    "averageTransactionAmount": value.averageTransactionAmount,
                    "notes": value.notes
                ]
            }

            let data = try JSONSerialization.data(withJSONObject: jsonData, options: [])
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            print("Failed to encode category breakdown to string: \(error)")
            return ""
        }
    }
}