//
//  Expense.swift
//  ExpenseTracker
//
//  Created by migration from Android Expense.kt
//

import Foundation
import CoreData

enum RecurrenceType: String, Codable {
    case NONE           // Tek seferlik
    case DAILY         // Her gün
    case WEEKDAYS       // Hafta içi her gün (Pazartesi-Cuma)
    case WEEKLY        // Haftada 1 kez
    case MONTHLY         // Ayda 1 kez

    var displayName: String {
        switch self {
        case .NONE:
            return "one_time".localized
        case .DAILY:
            return "daily".localized
        case .WEEKDAYS:
            return "weekdays".localized
        case .WEEKLY:
            return "weekly".localized
        case .MONTHLY:
            return "monthly".localized
        }
    }
}
struct Expense: Identifiable, Codable, Equatable {
    let id: String
    let amount: Double
    let currency: String
    let categoryId: String
    let subCategoryId: String
    let description: String
    let date: Date
    let dailyLimitAtCreation: Double
    let monthlyLimitAtCreation: Double
    let exchangeRate: Double?
    let recurrenceType: RecurrenceType
    let endDate: Date?
    let recurrenceGroupId: String?

    init(id: String = UUID().uuidString, amount: Double, currency: String, categoryId: String, subCategoryId: String, description: String, date: Date, dailyLimitAtCreation: Double, monthlyLimitAtCreation: Double, exchangeRate: Double? = nil, recurrenceType: RecurrenceType = .NONE, endDate: Date? = nil, recurrenceGroupId: String? = nil) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.description = description
        self.date = date
        self.dailyLimitAtCreation = dailyLimitAtCreation
        self.monthlyLimitAtCreation = monthlyLimitAtCreation
        self.exchangeRate = exchangeRate
        self.recurrenceType = recurrenceType
        self.endDate = endDate
        self.recurrenceGroupId = recurrenceGroupId
    }

    func getAmountInDefaultCurrency(defaultCurrency: String) -> Double {
        if currency == defaultCurrency || exchangeRate == nil {
            return amount
        } else {
            return amount * (exchangeRate ?? 1.0)
        }
    }

    func isActiveOnDate(targetDate: Date) -> Bool {
        let calendar = Calendar.current

        if targetDate < calendar.startOfDay(for: date) {
            return false
        }

        if let endDate = endDate, targetDate > endDate {
            return false
        }

        switch recurrenceType {
        case .DAILY:
            return true
        case .WEEKDAYS:
            let weekday = calendar.component(.weekday, from: targetDate)
            return weekday >= 2 && weekday <= 6
        case .WEEKLY:
            let startWeekday = calendar.component(.weekday, from: date)
            let targetWeekday = calendar.component(.weekday, from: targetDate)
            return startWeekday == targetWeekday
        case .MONTHLY:
            let startDay = calendar.component(.day, from: date)
            let targetDay = calendar.component(.day, from: targetDate)
            return startDay == targetDay
        case .NONE:
            return calendar.isDate(date, inSameDayAs: targetDate)
        }
    }
}

// MARK: - Core Data Conversion
extension Expense {
    init(from entity: ExpenseEntity) {
        self.id = entity.id ?? ""
        self.amount = entity.amount
        self.currency = entity.currency ?? ""
        self.categoryId = entity.categoryId ?? ""
        self.subCategoryId = entity.subCategoryId ?? ""
        self.description = entity.desc ?? ""
        self.date = entity.date ?? Date()
        self.dailyLimitAtCreation = entity.dailyLimitAtCreation
        self.monthlyLimitAtCreation = entity.monthlyLimitAtCreation
        self.exchangeRate = entity.exchangeRate
        self.recurrenceType = RecurrenceType(rawValue: entity.recurrenceType ?? "NONE") ?? .NONE
        self.endDate = entity.endDate
        self.recurrenceGroupId = entity.recurrenceGroupId
    }

    func toCoreData(context: NSManagedObjectContext) -> ExpenseEntity {
        let entity = ExpenseEntity(context: context)
        entity.id = self.id
        entity.amount = self.amount
        entity.currency = self.currency
        entity.categoryId = self.categoryId
        entity.subCategoryId = self.subCategoryId
        entity.desc = self.description
        entity.date = self.date
        entity.dailyLimitAtCreation = self.dailyLimitAtCreation
        entity.monthlyLimitAtCreation = self.monthlyLimitAtCreation
        entity.exchangeRate = self.exchangeRate ?? 0
        entity.recurrenceType = self.recurrenceType.rawValue
        entity.endDate = self.endDate
        entity.recurrenceGroupId = self.recurrenceGroupId
        return entity
    }
}
