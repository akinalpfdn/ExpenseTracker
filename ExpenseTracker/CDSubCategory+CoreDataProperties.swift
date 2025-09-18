//
//  CDSubCategory+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

extension CDSubCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSubCategory> {
        return NSFetchRequest<CDSubCategory>(entityName: "CDSubCategory")
    }

    @NSManaged public var budgetPercentage: Double
    @NSManaged public var categoryId: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var iconName: String?
    @NSManaged public var id: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var isDefault: Bool
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var subCategoryDescription: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var category: CDCategory?
    @NSManaged public var expenses: NSSet?

}

// MARK: Generated accessors for expenses
extension CDSubCategory {

    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: CDExpense)

    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: CDExpense)

    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)

    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)

}

extension CDSubCategory : Identifiable {

}