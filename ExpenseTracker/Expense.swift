//
//  Expense.swift
//  ExpenseTracker
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import Foundation
import SwiftUI

// MARK: - RecurrenceType Enum

/// Defines different types of expense recurrence patterns
enum RecurrenceType: String, CaseIterable, Identifiable, Codable {
    case none = "NONE"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case biweekly = "BIWEEKLY"
    case monthly = "MONTHLY"
    case quarterly = "QUARTERLY"
    case yearly = "YEARLY"
    case custom = "CUSTOM"

    var id: String { rawValue }

    /// Localized display name for the recurrence type
    var displayName: String {
        switch self {
        case .none:
            return L("recurrence_none")
        case .daily:
            return L("recurrence_daily")
        case .weekly:
            return L("recurrence_weekly")
        case .biweekly:
            return L("recurrence_biweekly")
        case .monthly:
            return L("recurrence_monthly")
        case .quarterly:
            return L("recurrence_quarterly")
        case .yearly:
            return L("recurrence_yearly")
        case .custom:
            return L("recurrence_custom")
        }
    }

    /// SF Symbol icon for the recurrence type
    var iconName: String {
        switch self {
        case .none:
            return "minus.circle"
        case .daily:
            return "calendar"
        case .weekly:
            return "calendar.badge.clock"
        case .biweekly:
            return "calendar.badge.plus"
        case .monthly:
            return "calendar.circle"
        case .quarterly:
            return "calendar.circle.fill"
        case .yearly:
            return "calendar.badge.exclamationmark"
        case .custom:
            return "calendar.badge.gear"
        }
    }

    /// Returns the number of days in the recurrence cycle
    var dayInterval: Int {
        switch self {
        case .none:
            return 0
        case .daily:
            return 1
        case .weekly:
            return 7
        case .biweekly:
            return 14
        case .monthly:
            return 30 // Approximation
        case .quarterly:
            return 90 // Approximation
        case .yearly:
            return 365 // Approximation
        case .custom:
            return 0 // Depends on custom configuration
        }
    }

    /// Calculates the next occurrence date from a given date
    /// - Parameter fromDate: The reference date
    /// - Returns: Next occurrence date or nil if non-recurring
    func nextOccurrence(from fromDate: Date) -> Date? {
        guard self != .none else { return nil }

        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: fromDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: fromDate)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: fromDate)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: fromDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: fromDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: fromDate)
        case .custom, .none:
            return nil
        }
    }

    /// Calculates all occurrences within a date range
    /// - Parameters:
    ///   - startDate: Start of the range
    ///   - endDate: End of the range
    ///   - fromDate: Base date for recurrence calculation
    /// - Returns: Array of occurrence dates
    func occurrences(from startDate: Date, to endDate: Date, baseDate: Date) -> [Date] {
        guard self != .none else { return [] }

        var occurrences: [Date] = []
        var currentDate = baseDate

        while currentDate <= endDate {
            if currentDate >= startDate {
                occurrences.append(currentDate)
            }

            guard let nextDate = nextOccurrence(from: currentDate) else { break }
            currentDate = nextDate

            // Safety check to prevent infinite loops
            if occurrences.count > 1000 { break }
        }

        return occurrences
    }
}

// MARK: - ExpenseStatus Enum

/// Represents the current status of an expense
enum ExpenseStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "PENDING"
    case confirmed = "CONFIRMED"
    case cancelled = "CANCELLED"
    case refunded = "REFUNDED"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending:
            return L("expense_status_pending")
        case .confirmed:
            return L("expense_status_confirmed")
        case .cancelled:
            return L("expense_status_cancelled")
        case .refunded:
            return L("expense_status_refunded")
        }
    }

    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .cancelled:
            return .red
        case .refunded:
            return .blue
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .confirmed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .refunded:
            return "arrow.uturn.backward.circle.fill"
        }
    }
}

// MARK: - Expense Model

/// Comprehensive expense model with full business logic and metadata
struct Expense: Identifiable, Hashable, Codable {
    let id: String
    var amount: Double
    var currency: String
    var categoryId: String
    var subCategoryId: String
    var description: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var dailyLimitAtCreation: Double
    var monthlyLimitAtCreation: Double
    var yearlyLimitAtCreation: Double
    var recurrenceType: RecurrenceType
    var recurrenceEndDate: Date?
    var customRecurrenceInterval: Int
    var status: ExpenseStatus
    var tags: [String]
    var notes: String
    var receiptImagePath: String?
    var location: String?
    var isRecurring: Bool
    var parentExpenseId: String?

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        amount: Double,
        currency: String = "TRY",
        categoryId: String,
        subCategoryId: String,
        description: String,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dailyLimitAtCreation: Double = 0.0,
        monthlyLimitAtCreation: Double = 0.0,
        yearlyLimitAtCreation: Double = 0.0,
        recurrenceType: RecurrenceType = .none,
        recurrenceEndDate: Date? = nil,
        customRecurrenceInterval: Int = 0,
        status: ExpenseStatus = .confirmed,
        tags: [String] = [],
        notes: String = "",
        receiptImagePath: String? = nil,
        location: String? = nil,
        isRecurring: Bool = false,
        parentExpenseId: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.categoryId = categoryId
        self.subCategoryId = subCategoryId
        self.description = description
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dailyLimitAtCreation = dailyLimitAtCreation
        self.monthlyLimitAtCreation = monthlyLimitAtCreation
        self.yearlyLimitAtCreation = yearlyLimitAtCreation
        self.recurrenceType = recurrenceType
        self.recurrenceEndDate = recurrenceEndDate
        self.customRecurrenceInterval = customRecurrenceInterval
        self.status = status
        self.tags = tags
        self.notes = notes
        self.receiptImagePath = receiptImagePath
        self.location = location
        self.isRecurring = isRecurring
        self.parentExpenseId = parentExpenseId
    }

    // MARK: - Computed Properties

    /// Returns formatted amount with currency
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }

    /// Returns localized date string
    var formattedDate: String {
        return DateConverters.dateToDisplayString(date)
    }

    /// Returns short date string for lists
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    /// Checks if expense is from today
    var isToday: Bool {
        return Calendar.current.isDateInToday(date)
    }

    /// Checks if expense is from this week
    var isThisWeek: Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Checks if expense is from this month
    var isThisMonth: Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }

    /// Checks if expense is from this year
    var isThisYear: Bool {
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
    }

    /// Returns true if expense has a receipt
    var hasReceipt: Bool {
        return receiptImagePath != nil && !receiptImagePath!.isEmpty
    }

    /// Returns true if expense has location information
    var hasLocation: Bool {
        return location != nil && !location!.isEmpty
    }

    /// Returns true if expense has tags
    var hasTags: Bool {
        return !tags.isEmpty
    }

    /// Returns true if expense has additional notes
    var hasNotes: Bool {
        return !notes.isEmpty
    }

    /// Returns the category (if available, needs to be resolved from categoryId)
    var category: CategoryType? {
        // This would typically be resolved by the data layer
        // For now, returning nil as we don't have access to the category repository
        return nil
    }

    // MARK: - Business Logic Methods

    /// Creates a copy of the expense with updated properties
    /// - Parameter updates: Dictionary of property updates
    /// - Returns: New Expense instance with updated properties
    func updated(with updates: [String: Any]) -> Expense {
        return Expense(
            id: self.id,
            amount: updates["amount"] as? Double ?? self.amount,
            currency: updates["currency"] as? String ?? self.currency,
            categoryId: updates["categoryId"] as? String ?? self.categoryId,
            subCategoryId: updates["subCategoryId"] as? String ?? self.subCategoryId,
            description: updates["description"] as? String ?? self.description,
            date: updates["date"] as? Date ?? self.date,
            createdAt: self.createdAt,
            updatedAt: Date(),
            dailyLimitAtCreation: self.dailyLimitAtCreation,
            monthlyLimitAtCreation: self.monthlyLimitAtCreation,
            yearlyLimitAtCreation: self.yearlyLimitAtCreation,
            recurrenceType: updates["recurrenceType"] as? RecurrenceType ?? self.recurrenceType,
            recurrenceEndDate: updates["recurrenceEndDate"] as? Date ?? self.recurrenceEndDate,
            customRecurrenceInterval: updates["customRecurrenceInterval"] as? Int ?? self.customRecurrenceInterval,
            status: updates["status"] as? ExpenseStatus ?? self.status,
            tags: updates["tags"] as? [String] ?? self.tags,
            notes: updates["notes"] as? String ?? self.notes,
            receiptImagePath: updates["receiptImagePath"] as? String ?? self.receiptImagePath,
            location: updates["location"] as? String ?? self.location,
            isRecurring: updates["isRecurring"] as? Bool ?? self.isRecurring,
            parentExpenseId: self.parentExpenseId
        )
    }

    /// Updates the expense status
    /// - Parameter newStatus: New status to set
    /// - Returns: New Expense instance with updated status
    func withStatus(_ newStatus: ExpenseStatus) -> Expense {
        return updated(with: ["status": newStatus])
    }

    /// Adds a tag to the expense
    /// - Parameter tag: Tag to add
    /// - Returns: New Expense instance with the tag added
    func addingTag(_ tag: String) -> Expense {
        guard !tags.contains(tag) else { return self }
        var newTags = tags
        newTags.append(tag)
        return updated(with: ["tags": newTags])
    }

    /// Removes a tag from the expense
    /// - Parameter tag: Tag to remove
    /// - Returns: New Expense instance with the tag removed
    func removingTag(_ tag: String) -> Expense {
        let newTags = tags.filter { $0 != tag }
        return updated(with: ["tags": newTags])
    }

    /// Adds or updates receipt image path
    /// - Parameter imagePath: Path to the receipt image
    /// - Returns: New Expense instance with updated receipt path
    func withReceiptImage(_ imagePath: String) -> Expense {
        return updated(with: ["receiptImagePath": imagePath])
    }

    /// Removes the receipt image
    /// - Returns: New Expense instance with receipt image removed
    func removingReceiptImage() -> Expense {
        return updated(with: ["receiptImagePath": nil])
    }

    /// Updates the location
    /// - Parameter location: New location string
    /// - Returns: New Expense instance with updated location
    func withLocation(_ location: String) -> Expense {
        return updated(with: ["location": location])
    }

    /// Creates recurring expenses based on the recurrence pattern
    /// - Parameters:
    ///   - endDate: End date for recurrence (uses recurrenceEndDate if not provided)
    ///   - maxOccurrences: Maximum number of occurrences to generate
    /// - Returns: Array of recurring expense instances
    func generateRecurringExpenses(until endDate: Date? = nil, maxOccurrences: Int = 50) -> [Expense] {
        guard recurrenceType != .none else { return [] }

        let finalEndDate = endDate ?? recurrenceEndDate ?? Calendar.current.date(byAdding: .year, value: 1, to: date) ?? date
        let occurrences = recurrenceType.occurrences(from: date, to: finalEndDate, baseDate: date)

        return occurrences.prefix(maxOccurrences).enumerated().compactMap { index, occurrenceDate in
            guard index > 0 else { return nil } // Skip the first occurrence (original expense)

            return Expense(
                amount: self.amount,
                currency: self.currency,
                categoryId: self.categoryId,
                subCategoryId: self.subCategoryId,
                description: "\(self.description) (\(L("recurring")))",
                date: occurrenceDate,
                dailyLimitAtCreation: self.dailyLimitAtCreation,
                monthlyLimitAtCreation: self.monthlyLimitAtCreation,
                yearlyLimitAtCreation: self.yearlyLimitAtCreation,
                recurrenceType: self.recurrenceType,
                recurrenceEndDate: self.recurrenceEndDate,
                customRecurrenceInterval: self.customRecurrenceInterval,
                status: .pending, // Recurring expenses start as pending
                tags: self.tags,
                notes: self.notes,
                location: self.location,
                isRecurring: true,
                parentExpenseId: self.id
            )
        }
    }

    /// Calculates the total amount for all recurring instances
    /// - Parameter endDate: End date for calculation
    /// - Returns: Total amount across all recurrences
    func totalRecurringAmount(until endDate: Date? = nil) -> Double {
        let recurringExpenses = generateRecurringExpenses(until: endDate)
        return recurringExpenses.reduce(amount) { $0 + $1.amount }
    }

    /// Checks if this expense exceeds any of the limits it was created with
    /// - Returns: Dictionary indicating which limits are exceeded
    func limitExceedanceCheck() -> [String: Bool] {
        return [
            "daily": amount > dailyLimitAtCreation && dailyLimitAtCreation > 0,
            "monthly": amount > monthlyLimitAtCreation && monthlyLimitAtCreation > 0,
            "yearly": amount > yearlyLimitAtCreation && yearlyLimitAtCreation > 0
        ]
    }

    /// Generates a summary string for the expense
    /// - Returns: Formatted summary string
    func generateSummary() -> String {
        var summary = "\(formattedAmount) - \(description)"

        if isRecurring {
            summary += " (\(recurrenceType.displayName))"
        }

        if status != .confirmed {
            summary += " [\(status.displayName)]"
        }

        return summary
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(amount)
        hasher.combine(date)
        hasher.combine(description)
    }

    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Legacy Compatibility

/// Legacy expense category enum for backward compatibility
enum ExpenseCategory: String, CaseIterable {
    case food = "Gıda ve İçecek"
    case housing = "Konut"
    case transportation = "Ulaşım"
    case health = "Sağlık ve Kişisel Bakım"
    case entertainment = "Eğlence ve Hobiler"
    case education = "Eğitim"
    case shopping = "Alışveriş"
    case pets = "Evcil Hayvan"
    case work = "İş ve Profesyonel Harcamalar"
    case tax = "Vergi ve Hukuki Harcamalar"
    case donations = "Bağışlar ve Yardımlar"

    /// Maps to new CategoryType
    var categoryType: CategoryType {
        switch self {
        case .food: return .food
        case .housing: return .housing
        case .transportation: return .transportation
        case .health: return .health
        case .entertainment: return .entertainment
        case .education: return .education
        case .shopping: return .shopping
        case .pets: return .pets
        case .work: return .work
        case .tax: return .tax
        case .donations: return .donations
        }
    }
}

/// Legacy expense subcategory struct for backward compatibility
struct ExpenseSubCategory {
    let name: String
    let category: ExpenseCategory
}

// MARK: - Array Extensions for Expense Management

extension Array where Element == Expense {
    /// Filters expenses by status
    /// - Parameter status: Status to filter by
    /// - Returns: Array of expenses with matching status
    func expenses(with status: ExpenseStatus) -> [Expense] {
        return filter { $0.status == status }
    }

    /// Filters expenses by date range
    /// - Parameters:
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of expenses within the date range
    func expenses(from startDate: Date, to endDate: Date) -> [Expense] {
        return filter { $0.date >= startDate && $0.date <= endDate }
    }

    /// Filters expenses by category
    /// - Parameter categoryId: Category ID to filter by
    /// - Returns: Array of expenses in the category
    func expenses(in categoryId: String) -> [Expense] {
        return filter { $0.categoryId == categoryId }
    }

    /// Calculates total amount
    var totalAmount: Double {
        return reduce(0) { $0 + $1.amount }
    }

    /// Groups expenses by category
    var groupedByCategory: [String: [Expense]] {
        return Dictionary(grouping: self) { $0.categoryId }
    }

    /// Groups expenses by month
    var groupedByMonth: [String: [Expense]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return Dictionary(grouping: self) { formatter.string(from: $0.date) }
    }

    /// Sorts expenses by date (newest first)
    var sortedByDateDescending: [Expense] {
        return sorted { $0.date > $1.date }
    }

    /// Sorts expenses by amount (highest first)
    var sortedByAmountDescending: [Expense] {
        return sorted { $0.amount > $1.amount }
    }

    /// Finds recurring expenses
    var recurringExpenses: [Expense] {
        return filter { $0.isRecurring || $0.recurrenceType != .none }
    }

    /// Finds expenses with receipts
    var expensesWithReceipts: [Expense] {
        return filter { $0.hasReceipt }
    }
}
