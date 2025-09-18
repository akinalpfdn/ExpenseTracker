//
//  CDCategory+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

extension CDCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCategory> {
        return NSFetchRequest<CDCategory>(entityName: "CDCategory")
    }

    @NSManaged public var budgetPercentage: Double
    @NSManaged public var categoryDescription: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var iconName: String?
    @NSManaged public var id: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var isDefault: Bool
    @NSManaged public var name: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var updatedAt: Date?
    @NSManaged public var expenses: NSSet?
    @NSManaged public var subCategories: NSSet?

}

// MARK: Generated accessors for expenses
extension CDCategory {

    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: CDExpense)

    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: CDExpense)

    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)

    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)

}

// MARK: Generated accessors for subCategories
extension CDCategory {

    @objc(addSubCategoriesObject:)
    @NSManaged public func addToSubCategories(_ value: CDSubCategory)

    @objc(removeSubCategoriesObject:)
    @NSManaged public func removeFromSubCategories(_ value: CDSubCategory)

    @objc(addSubCategories:)
    @NSManaged public func addToSubCategories(_ values: NSSet)

    @objc(removeSubCategories:)
    @NSManaged public func removeFromSubCategories(_ values: NSSet)

}

extension CDCategory : Identifiable {

}