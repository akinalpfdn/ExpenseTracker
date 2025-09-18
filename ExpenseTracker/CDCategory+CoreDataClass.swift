//
//  CDCategory+CoreDataClass.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

@objc(CDCategory)
public class CDCategory: NSManagedObject {

    /// Converts Core Data entity to Swift model
    func toCategory() -> Category {
        return Category(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            iconName: iconName ?? "",
            colorHex: colorHex ?? "",
            isActive: isActive,
            sortOrder: Int(sortOrder),
            description: categoryDescription ?? "",
            budgetPercentage: budgetPercentage,
            isDefault: isDefault,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    /// Updates Core Data entity from Swift model
    func update(from category: Category) {
        id = category.id
        name = category.name
        iconName = category.iconName
        colorHex = category.colorHex
        isActive = category.isActive
        sortOrder = Int32(category.sortOrder)
        categoryDescription = category.description
        budgetPercentage = category.budgetPercentage
        isDefault = category.isDefault
        createdAt = category.createdAt
        updatedAt = category.updatedAt
    }

    /// Creates a new CDCategory from a Category model
    /// - Parameters:
    ///   - category: The Category model
    ///   - context: The managed object context
    /// - Returns: New CDCategory instance
    static func from(_ category: Category, context: NSManagedObjectContext) -> CDCategory {
        let cdCategory = CDCategory(context: context)
        cdCategory.update(from: category)
        return cdCategory
    }
}