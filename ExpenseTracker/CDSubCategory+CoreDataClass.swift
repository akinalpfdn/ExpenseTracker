//
//  CDSubCategory+CoreDataClass.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData

@objc(CDSubCategory)
public class CDSubCategory: NSManagedObject {

    /// Converts Core Data entity to Swift model
    func toSubCategory() -> SubCategory {
        return SubCategory(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            categoryId: categoryId ?? "",
            iconName: iconName ?? "",
            colorHex: colorHex ?? "",
            isActive: isActive,
            sortOrder: Int(sortOrder),
            description: subCategoryDescription ?? "",
            budgetPercentage: budgetPercentage,
            isDefault: isDefault,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    /// Updates Core Data entity from Swift model
    func update(from subCategory: SubCategory) {
        id = subCategory.id
        name = subCategory.name
        categoryId = subCategory.categoryId
        iconName = subCategory.iconName
        colorHex = subCategory.colorHex
        isActive = subCategory.isActive
        sortOrder = Int32(subCategory.sortOrder)
        subCategoryDescription = subCategory.description
        budgetPercentage = subCategory.budgetPercentage
        isDefault = subCategory.isDefault
        createdAt = subCategory.createdAt
        updatedAt = subCategory.updatedAt
    }

    /// Creates a new CDSubCategory from a SubCategory model
    /// - Parameters:
    ///   - subCategory: The SubCategory model
    ///   - context: The managed object context
    /// - Returns: New CDSubCategory instance
    static func from(_ subCategory: SubCategory, context: NSManagedObjectContext) -> CDSubCategory {
        let cdSubCategory = CDSubCategory(context: context)
        cdSubCategory.update(from: subCategory)
        return cdSubCategory
    }
}