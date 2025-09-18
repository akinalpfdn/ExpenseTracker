//
//  CDFinancialPlan+CoreDataClass.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

@objc(CDFinancialPlan)
public class CDFinancialPlan: NSManagedObject {

    /// Converts Core Data entity to Swift model
    func toFinancialPlan() -> FinancialPlan {
        let interestType = InterestType(rawValue: self.interestType ?? "") ?? .compound
        let categoryAllocationsDict = parseDictionary(from: categoryAllocations)
        let monthlyIncomeBreakdownDict = parseDictionary(from: monthlyIncomeBreakdown)
        let fixedExpensesDict = parseDictionary(from: fixedExpenses)
        let variableExpenseBudgetsDict = parseDictionary(from: variableExpenseBudgets)
        let savingsContributionsDict = parseDictionary(from: savingsContributions)
        let actualExpensesDict = parseDictionary(from: actualExpenses)
        let tagsArray = tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []

        return FinancialPlan(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            description: planDescription ?? "",
            startDate: startDate ?? Date(),
            endDate: endDate ?? Date(),
            totalIncome: totalIncome,
            totalBudget: totalBudget,
            savingsGoal: savingsGoal,
            emergencyFundGoal: emergencyFundGoal,
            interestType: interestType,
            annualInterestRate: annualInterestRate,
            compoundingFrequency: Int(compoundingFrequency),
            isActive: isActive,
            currency: currency ?? "TRY",
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date(),
            categoryAllocations: categoryAllocationsDict,
            monthlyIncomeBreakdown: monthlyIncomeBreakdownDict,
            fixedExpenses: fixedExpensesDict,
            variableExpenseBudgets: variableExpenseBudgetsDict,
            savingsContributions: savingsContributionsDict,
            actualExpenses: actualExpensesDict,
            notes: notes ?? "",
            tags: tagsArray
        )
    }

    /// Updates Core Data entity from Swift model
    func update(from plan: FinancialPlan) {
        id = plan.id
        name = plan.name
        planDescription = plan.description
        startDate = plan.startDate
        endDate = plan.endDate
        totalIncome = plan.totalIncome
        totalBudget = plan.totalBudget
        savingsGoal = plan.savingsGoal
        emergencyFundGoal = plan.emergencyFundGoal
        interestType = plan.interestType.rawValue
        annualInterestRate = plan.annualInterestRate
        compoundingFrequency = Int32(plan.compoundingFrequency)
        isActive = plan.isActive
        currency = plan.currency
        createdAt = plan.createdAt
        updatedAt = plan.updatedAt
        categoryAllocations = encodeDictionary(plan.categoryAllocations)
        monthlyIncomeBreakdown = encodeDictionary(plan.monthlyIncomeBreakdown)
        fixedExpenses = encodeDictionary(plan.fixedExpenses)
        variableExpenseBudgets = encodeDictionary(plan.variableExpenseBudgets)
        savingsContributions = encodeDictionary(plan.savingsContributions)
        actualExpenses = encodeDictionary(plan.actualExpenses)
        notes = plan.notes
        tags = plan.tags.joined(separator: ",")
    }

    /// Creates a new CDFinancialPlan from a FinancialPlan model
    /// - Parameters:
    ///   - plan: The FinancialPlan model
    ///   - context: The managed object context
    /// - Returns: New CDFinancialPlan instance
    static func from(_ plan: FinancialPlan, context: NSManagedObjectContext) -> CDFinancialPlan {
        let cdPlan = CDFinancialPlan(context: context)
        cdPlan.update(from: plan)
        return cdPlan
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
}