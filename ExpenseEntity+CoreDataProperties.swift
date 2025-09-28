//
//  ExpenseEntity+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 28.09.2025.
//
//

import Foundation
import CoreData


extension ExpenseEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        return NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var amount: Double
    @NSManaged public var currency: String?
    @NSManaged public var categoryId: String?
    @NSManaged public var desc: String?
    @NSManaged public var date: Date?
    @NSManaged public var dailyLimitAtCreation: Double
    @NSManaged public var monthlyLimitAtCreation: Double
    @NSManaged public var exchangeRate: Double
    @NSManaged public var recurrenceType: String?
    @NSManaged public var endDate: Date?
    @NSManaged public var recurrenceGroupId: String?
    @NSManaged public var subCategoryId: String?
    @NSManaged public var category: CategoryEntity?
    @NSManaged public var subcategory: SubCategoryEntity?

}

extension ExpenseEntity : Identifiable {

}
