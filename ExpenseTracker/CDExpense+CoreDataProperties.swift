//
//  CDExpense+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

extension CDExpense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDExpense> {
        return NSFetchRequest<CDExpense>(entityName: "CDExpense")
    }

    @NSManaged public var amount: Double
    @NSManaged public var categoryId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var currency: String?
    @NSManaged public var customRecurrenceInterval: Int32
    @NSManaged public var dailyLimitAtCreation: Double
    @NSManaged public var date: Date?
    @NSManaged public var expenseDescription: String?
    @NSManaged public var id: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var location: String?
    @NSManaged public var monthlyLimitAtCreation: Double
    @NSManaged public var notes: String?
    @NSManaged public var parentExpenseId: String?
    @NSManaged public var receiptImagePath: String?
    @NSManaged public var recurrenceEndDate: Date?
    @NSManaged public var recurrenceType: String?
    @NSManaged public var status: String?
    @NSManaged public var subCategoryId: String?
    @NSManaged public var tags: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var yearlyLimitAtCreation: Double
    @NSManaged public var category: CDCategory?
    @NSManaged public var subCategory: CDSubCategory?

}

extension CDExpense : Identifiable {

}