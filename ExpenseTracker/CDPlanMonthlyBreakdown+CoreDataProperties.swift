//
//  CDPlanMonthlyBreakdown+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

extension CDPlanMonthlyBreakdown {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPlanMonthlyBreakdown> {
        return NSFetchRequest<CDPlanMonthlyBreakdown>(entityName: "CDPlanMonthlyBreakdown")
    }

    @NSManaged public var actualExpenses: Double
    @NSManaged public var actualIncome: Double
    @NSManaged public var actualSavings: Double
    @NSManaged public var categoryBreakdown: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var debtPayment: Double
    @NSManaged public var emergencyFundContribution: Double
    @NSManaged public var expensesBySubCategory: String?
    @NSManaged public var fixedExpenses: Double
    @NSManaged public var id: String?
    @NSManaged public var investmentContribution: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var month: String?
    @NSManaged public var monthNumber: Int32
    @NSManaged public var notes: String?
    @NSManaged public var planId: String?
    @NSManaged public var plannedExpenses: Double
    @NSManaged public var plannedIncome: Double
    @NSManaged public var plannedSavings: Double
    @NSManaged public var updatedAt: Date?
    @NSManaged public var variableExpenses: Double
    @NSManaged public var year: Int32
    @NSManaged public var plan: CDFinancialPlan?

}

extension CDPlanMonthlyBreakdown : Identifiable {

}