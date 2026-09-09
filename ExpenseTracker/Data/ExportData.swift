//
//  ExportData.swift
//  ExpenseTracker
//
//  Created by migration from Android ExportData.kt
//
//  Backup file schema. The JSON produced here is intentionally identical to the
//  Android build's, so a backup taken on one platform can be restored on the other.
//

import Foundation

// MARK: - Backup Schema Constants

enum BackupSchema {
    /// Format revision of the backup envelope itself.
    static let exportVersion = 1

    /// Mirrors the Room schema version on Android. Import refuses files above this.
    static let databaseVersion = 11
}

// MARK: - LocalDateTime Bridging

/// Android serialises dates with `LocalDateTime.toString()` — a wall-clock timestamp
/// with no time zone. Java omits the seconds component when it is zero and the
/// fractional part when it is zero, so the same file can contain `2025-11-09T23:50`,
/// `2025-11-09T23:50:21` and `2025-11-09T23:50:21.123456789`.
///
/// We write the full-precision form (which Java parses without complaint) and accept
/// every shape Java can emit.
enum LocalDateTimeFormat {

    /// Fixed reference calendar: no localised digits, no alternate calendar.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = format
        return formatter
    }

    private static let writer = makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS")

    /// Ordered most-specific first so a value with fractions is not truncated.
    private static let readers: [DateFormatter] = [
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS"),
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss"),
        makeFormatter("yyyy-MM-dd'T'HH:mm")
    ]

    static func string(from date: Date) -> String {
        return writer.string(from: date)
    }

    static func date(from string: String) -> Date? {
        // Java emits up to 9 fractional digits; DateFormatter handles at most 3.
        // Trim the excess rather than failing — sub-millisecond precision is not
        // meaningful for an expense timestamp.
        let normalized = normalizeFractionalSeconds(string)

        for reader in readers {
            if let date = reader.date(from: normalized) {
                return date
            }
        }
        return nil
    }

    /// Truncates a fractional-seconds component to at most 3 digits.
    private static func normalizeFractionalSeconds(_ value: String) -> String {
        guard let dotIndex = value.lastIndex(of: ".") else { return value }

        let fractionStart = value.index(after: dotIndex)
        let fraction = value[fractionStart...]

        // Only touch it if the fraction is all digits and longer than 3.
        guard fraction.allSatisfy({ $0.isNumber }), fraction.count > 3 else { return value }

        let truncated = fraction.prefix(3)
        return String(value[..<fractionStart]) + truncated
    }
}

// MARK: - Envelope

struct ExportData: Codable {
    let exportVersion: Int
    let appVersion: String
    let exportDate: String
    let databaseVersion: Int
    let categories: [CategoryDto]
    let subCategories: [SubCategoryDto]
    let expenses: [ExpenseDto]
    let financialPlans: [FinancialPlanDto]
    let planMonthlyBreakdowns: [PlanMonthlyBreakdownDto]
}

// MARK: - DTOs

struct CategoryDto: Codable {
    let id: String
    let name: String
    let colorHex: String
    let iconName: String
    let isDefault: Bool
    let isCustom: Bool
}

struct SubCategoryDto: Codable {
    let id: String
    let name: String
    let categoryId: String
    let isDefault: Bool
    let isCustom: Bool
}

struct ExpenseDto: Codable {
    let id: String
    let amount: Double
    let currency: String
    let categoryId: String
    let subCategoryId: String
    let description: String
    let date: String
    let dailyLimitAtCreation: Double
    let monthlyLimitAtCreation: Double
    let exchangeRate: Double?
    let recurrenceType: String
    let endDate: String?
    let recurrenceGroupId: String?
}

struct FinancialPlanDto: Codable {
    let id: String
    let name: String
    let startDate: String
    let durationInMonths: Int
    let monthlyIncome: Double
    let manualMonthlyExpenses: Double
    let useAppExpenseData: Bool
    let isInflationApplied: Bool
    let inflationRate: Double
    let isInterestApplied: Bool
    let interestRate: Double
    let interestType: String
    let createdAt: String
    let updatedAt: String
    let defaultCurrency: String
}

struct PlanMonthlyBreakdownDto: Codable {
    let id: String
    let planId: String
    let monthIndex: Int
    let projectedIncome: Double
    let fixedExpenses: Double
    let averageExpenses: Double
    let totalProjectedExpenses: Double
    let netAmount: Double
    let interestEarned: Double
    let cumulativeNet: Double
}

// MARK: - Entity to DTO

extension Category {
    func toDto() -> CategoryDto {
        return CategoryDto(
            id: id,
            name: name,
            colorHex: colorHex,
            iconName: iconName,
            isDefault: isDefault,
            isCustom: isCustom
        )
    }
}

extension SubCategory {
    func toDto() -> SubCategoryDto {
        return SubCategoryDto(
            id: id,
            name: name,
            categoryId: categoryId,
            isDefault: isDefault,
            isCustom: isCustom
        )
    }
}

extension Expense {
    func toDto() -> ExpenseDto {
        return ExpenseDto(
            id: id,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            description: description,
            date: LocalDateTimeFormat.string(from: date),
            dailyLimitAtCreation: dailyLimitAtCreation,
            monthlyLimitAtCreation: monthlyLimitAtCreation,
            // Core Data stores this as a non-optional scalar, so "no rate" comes back
            // as 0 rather than nil. Writing that 0 into the file would be actively
            // harmful: both platforms compute `amount * exchangeRate` for a foreign
            // currency, which would zero the expense out. Normalise back to null.
            exchangeRate: (exchangeRate ?? 0) == 0 ? nil : exchangeRate,
            recurrenceType: recurrenceType.rawValue,
            endDate: endDate.map { LocalDateTimeFormat.string(from: $0) },
            recurrenceGroupId: recurrenceGroupId
        )
    }
}

extension FinancialPlan {
    func toDto() -> FinancialPlanDto {
        return FinancialPlanDto(
            id: id,
            name: name,
            startDate: LocalDateTimeFormat.string(from: startDate),
            durationInMonths: durationInMonths,
            monthlyIncome: monthlyIncome,
            manualMonthlyExpenses: manualMonthlyExpenses,
            useAppExpenseData: useAppExpenseData,
            isInflationApplied: isInflationApplied,
            inflationRate: inflationRate,
            isInterestApplied: isInterestApplied,
            interestRate: interestRate,
            interestType: interestType.rawValue,
            createdAt: LocalDateTimeFormat.string(from: createdAt),
            updatedAt: LocalDateTimeFormat.string(from: updatedAt),
            defaultCurrency: defaultCurrency
        )
    }
}

extension PlanMonthlyBreakdown {
    func toDto() -> PlanMonthlyBreakdownDto {
        return PlanMonthlyBreakdownDto(
            id: id,
            planId: planId,
            monthIndex: monthIndex,
            projectedIncome: projectedIncome,
            fixedExpenses: fixedExpenses,
            averageExpenses: averageExpenses,
            totalProjectedExpenses: totalProjectedExpenses,
            netAmount: netAmount,
            interestEarned: interestEarned,
            cumulativeNet: cumulativeNet
        )
    }
}

// MARK: - DTO to Entity

extension CategoryDto {
    func toEntity() -> Category {
        return Category(
            id: id,
            name: name,
            colorHex: colorHex,
            iconName: iconName,
            isDefault: isDefault,
            isCustom: isCustom
        )
    }
}

extension SubCategoryDto {
    func toEntity() -> SubCategory {
        return SubCategory(
            id: id,
            name: name,
            categoryId: categoryId,
            isDefault: isDefault,
            isCustom: isCustom
        )
    }
}

extension ExpenseDto {
    func toEntity() throws -> Expense {
        guard let parsedDate = LocalDateTimeFormat.date(from: date) else {
            throw BackupError.malformedDate(field: "expense.date", value: date)
        }

        var parsedEndDate: Date?
        if let endDate = endDate {
            guard let value = LocalDateTimeFormat.date(from: endDate) else {
                throw BackupError.malformedDate(field: "expense.endDate", value: endDate)
            }
            parsedEndDate = value
        }

        guard let recurrence = RecurrenceType(rawValue: recurrenceType) else {
            throw BackupError.unknownEnumValue(field: "expense.recurrenceType", value: recurrenceType)
        }

        return Expense(
            id: id,
            amount: amount,
            currency: currency,
            categoryId: categoryId,
            subCategoryId: subCategoryId,
            description: description,
            date: parsedDate,
            dailyLimitAtCreation: dailyLimitAtCreation,
            monthlyLimitAtCreation: monthlyLimitAtCreation,
            // Symmetric with `toDto`: a 0 in the file means "no rate", not a rate of 0.
            exchangeRate: (exchangeRate ?? 0) == 0 ? nil : exchangeRate,
            recurrenceType: recurrence,
            endDate: parsedEndDate,
            recurrenceGroupId: recurrenceGroupId
        )
    }
}

extension FinancialPlanDto {
    func toEntity() throws -> FinancialPlan {
        guard let parsedStart = LocalDateTimeFormat.date(from: startDate) else {
            throw BackupError.malformedDate(field: "plan.startDate", value: startDate)
        }
        guard let parsedCreated = LocalDateTimeFormat.date(from: createdAt) else {
            throw BackupError.malformedDate(field: "plan.createdAt", value: createdAt)
        }
        guard let parsedUpdated = LocalDateTimeFormat.date(from: updatedAt) else {
            throw BackupError.malformedDate(field: "plan.updatedAt", value: updatedAt)
        }
        guard let interest = InterestType(rawValue: interestType) else {
            throw BackupError.unknownEnumValue(field: "plan.interestType", value: interestType)
        }

        return FinancialPlan(
            id: id,
            name: name,
            startDate: parsedStart,
            durationInMonths: durationInMonths,
            monthlyIncome: monthlyIncome,
            manualMonthlyExpenses: manualMonthlyExpenses,
            useAppExpenseData: useAppExpenseData,
            isInflationApplied: isInflationApplied,
            inflationRate: inflationRate,
            isInterestApplied: isInterestApplied,
            interestRate: interestRate,
            interestType: interest,
            createdAt: parsedCreated,
            updatedAt: parsedUpdated,
            defaultCurrency: defaultCurrency
        )
    }
}

extension PlanMonthlyBreakdownDto {
    func toEntity() -> PlanMonthlyBreakdown {
        return PlanMonthlyBreakdown(
            id: id,
            planId: planId,
            monthIndex: monthIndex,
            projectedIncome: projectedIncome,
            fixedExpenses: fixedExpenses,
            averageExpenses: averageExpenses,
            totalProjectedExpenses: totalProjectedExpenses,
            netAmount: netAmount,
            interestEarned: interestEarned,
            cumulativeNet: cumulativeNet
        )
    }
}
