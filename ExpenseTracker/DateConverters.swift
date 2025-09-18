//
//  DateConverters.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation

/// Utility class for converting between different date formats and enum values
/// Replaces Room type converters from Android with Swift-compatible utilities
class DateConverters {

    // MARK: - Date Formatting

    /// Standard date formatter for API communication (ISO 8601)
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Date formatter for storage (simplified format)
    static let storageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Date formatter for display purposes
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()

    /// Date formatter for day-only display
    static let dayOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Date to String Conversion

    /// Converts Date to string for API communication
    /// - Parameter date: The date to convert
    /// - Returns: ISO 8601 formatted string
    static func dateToApiString(_ date: Date) -> String {
        return apiDateFormatter.string(from: date)
    }

    /// Converts Date to string for storage
    /// - Parameter date: The date to convert
    /// - Returns: Storage formatted string
    static func dateToStorageString(_ date: Date) -> String {
        return storageDateFormatter.string(from: date)
    }

    /// Converts Date to string for display
    /// - Parameter date: The date to convert
    /// - Returns: Localized display string
    static func dateToDisplayString(_ date: Date) -> String {
        return displayDateFormatter.string(from: date)
    }

    /// Converts Date to day-only string
    /// - Parameter date: The date to convert
    /// - Returns: YYYY-MM-DD formatted string
    static func dateToDayString(_ date: Date) -> String {
        return dayOnlyFormatter.string(from: date)
    }

    // MARK: - String to Date Conversion

    /// Converts API string to Date
    /// - Parameter string: ISO 8601 formatted string
    /// - Returns: Date object or nil if parsing fails
    static func apiStringToDate(_ string: String) -> Date? {
        return apiDateFormatter.date(from: string)
    }

    /// Converts storage string to Date
    /// - Parameter string: Storage formatted string
    /// - Returns: Date object or nil if parsing fails
    static func storageStringToDate(_ string: String) -> Date? {
        return storageDateFormatter.date(from: string)
    }

    /// Converts day string to Date (sets time to start of day)
    /// - Parameter string: YYYY-MM-DD formatted string
    /// - Returns: Date object or nil if parsing fails
    static func dayStringToDate(_ string: String) -> Date? {
        return dayOnlyFormatter.date(from: string)
    }

    // MARK: - InterestType Conversion

    /// Converts InterestType to String for storage
    /// - Parameter interestType: The InterestType enum value
    /// - Returns: String representation
    static func interestTypeToString(_ interestType: InterestType) -> String {
        return interestType.rawValue
    }

    /// Converts String to InterestType
    /// - Parameter string: String representation of InterestType
    /// - Returns: InterestType enum value or .simple as default
    static func stringToInterestType(_ string: String) -> InterestType {
        return InterestType(rawValue: string) ?? .simple
    }

    // MARK: - Date Utility Methods

    /// Gets the start of day for a given date
    /// - Parameter date: The input date
    /// - Returns: Date set to start of day (00:00:00)
    static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }

    /// Gets the end of day for a given date
    /// - Parameter date: The input date
    /// - Returns: Date set to end of day (23:59:59)
    static func endOfDay(for date: Date) -> Date {
        let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(for: date))!
        return Calendar.current.date(byAdding: .second, value: -1, to: startOfNextDay)!
    }

    /// Gets the start of month for a given date
    /// - Parameter date: The input date
    /// - Returns: Date set to first day of month at start of day
    static func startOfMonth(for date: Date) -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: components)!
    }

    /// Gets the end of month for a given date
    /// - Parameter date: The input date
    /// - Returns: Date set to last day of month at end of day
    static func endOfMonth(for date: Date) -> Date {
        let startOfNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth(for: date))!
        return Calendar.current.date(byAdding: .second, value: -1, to: startOfNextMonth)!
    }

    /// Checks if two dates are in the same day
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if both dates are in the same day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    /// Checks if two dates are in the same month
    /// - Parameters:
    ///   - date1: First date
    ///   - date2: Second date
    /// - Returns: True if both dates are in the same month and year
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let components1 = Calendar.current.dateComponents([.year, .month], from: date1)
        let components2 = Calendar.current.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }

    /// Gets the number of days between two dates
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days between the dates
    static func daysBetween(from: Date, to: Date) -> Int {
        let fromDay = startOfDay(for: from)
        let toDay = startOfDay(for: to)
        let components = Calendar.current.dateComponents([.day], from: fromDay, to: toDay)
        return components.day ?? 0
    }

    /// Gets the number of months between two dates
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of months between the dates
    static func monthsBetween(from: Date, to: Date) -> Int {
        let components = Calendar.current.dateComponents([.month], from: from, to: to)
        return components.month ?? 0
    }
}

// MARK: - Date Extensions for Convenience

extension Date {
    /// Converts date to API string format
    var apiString: String {
        return DateConverters.dateToApiString(self)
    }

    /// Converts date to storage string format
    var storageString: String {
        return DateConverters.dateToStorageString(self)
    }

    /// Converts date to display string format
    var displayString: String {
        return DateConverters.dateToDisplayString(self)
    }

    /// Converts date to day-only string format
    var dayString: String {
        return DateConverters.dateToDayString(self)
    }

    /// Returns the start of day for this date
    var startOfDay: Date {
        return DateConverters.startOfDay(for: self)
    }

    /// Returns the end of day for this date
    var endOfDay: Date {
        return DateConverters.endOfDay(for: self)
    }

    /// Returns the start of month for this date
    var startOfMonth: Date {
        return DateConverters.startOfMonth(for: self)
    }

    /// Returns the end of month for this date
    var endOfMonth: Date {
        return DateConverters.endOfMonth(for: self)
    }
}

// MARK: - String Extensions for Date Parsing

extension String {
    /// Converts API string to Date
    var apiStringToDate: Date? {
        return DateConverters.apiStringToDate(self)
    }

    /// Converts storage string to Date
    var storageStringToDate: Date? {
        return DateConverters.storageStringToDate(self)
    }

    /// Converts day string to Date
    var dayStringToDate: Date? {
        return DateConverters.dayStringToDate(self)
    }

    /// Converts string to InterestType
    var toInterestType: InterestType {
        return DateConverters.stringToInterestType(self)
    }
}