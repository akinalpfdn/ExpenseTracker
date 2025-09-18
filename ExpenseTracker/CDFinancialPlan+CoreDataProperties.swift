//
//  CDFinancialPlan+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

extension CDFinancialPlan {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDFinancialPlan> {
        return NSFetchRequest<CDFinancialPlan>(entityName: "CDFinancialPlan")
    }

    @NSManaged public var actualExpenses: String?
    @NSManaged public var annualInterestRate: Double
    @NSManaged public var categoryAllocations: String?
    @NSManaged public var compoundingFrequency: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var currency: String?
    @NSManaged public var emergencyFundGoal: Double
    @NSManaged public var endDate: Date?
    @NSManaged public var fixedExpenses: String?
    @NSManaged public var id: String?
    @NSManaged public var interestType: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var monthlyIncomeBreakdown: String?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var planDescription: String?
    @NSManaged public var savingsContributions: String?
    @NSManaged public var savingsGoal: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var tags: String?
    @NSManaged public var totalBudget: Double
    @NSManaged public var totalIncome: Double
    @NSManaged public var updatedAt: Date?
    @NSManaged public var variableExpenseBudgets: String?
    @NSManaged public var monthlyBreakdowns: NSSet?

}

// MARK: Generated accessors for monthlyBreakdowns
extension CDFinancialPlan {

    @objc(addMonthlyBreakdownsObject:)
    @NSManaged public func addToMonthlyBreakdowns(_ value: CDPlanMonthlyBreakdown)

    @objc(removeMonthlyBreakdownsObject:)
    @NSManaged public func removeFromMonthlyBreakdowns(_ value: CDPlanMonthlyBreakdown)

    @objc(addMonthlyBreakdowns:)
    @NSManaged public func addToMonthlyBreakdowns(_ values: NSSet)

    @objc(removeMonthlyBreakdowns:)
    @NSManaged public func removeFromMonthlyBreakdowns(_ values: NSSet)

}

extension CDFinancialPlan : Identifiable {

}