//
//  DateConverters.swift
//  ExpenseTracker
//
//  Created by migration from Android Converters.kt
//

import Foundation

class Converters {

    private let formatter = ISO8601DateFormatter()

    func fromDate(_ value: Date?) -> String? {
        return value?.timeIntervalSince1970.description
    }

    func toDate(_ value: String?) -> Date? {
        guard let value = value, let timeInterval = Double(value) else { return nil }
        return Date(timeIntervalSince1970: timeInterval)
    }

    func fromRecurrenceType(_ value: RecurrenceType?) -> String? {
        switch value {
        case .NONE: return "NONE"
        case .DAILY: return "DAILY"
        case .WEEKDAYS: return "WEEKDAYS"
        case .WEEKLY: return "WEEKLY"
        case .MONTHLY: return "MONTHLY"
        case .none: return nil
        }
    }

    func toRecurrenceType(_ value: String?) -> RecurrenceType? {
        guard let value = value else { return nil }
        switch value {
        case "NONE": return .NONE
        case "DAILY": return .DAILY
        case "WEEKDAYS": return .WEEKDAYS
        case "WEEKLY": return .WEEKLY
        case "MONTHLY": return .MONTHLY
        default: return nil
        }
    }
}

 
