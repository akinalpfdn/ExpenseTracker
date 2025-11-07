//
//  CurrencyFormatter.swift
//  ExpenseTracker
//
//  Currency input formatting utilities with locale support
//

import Foundation

struct CurrencyInputFormatter {
    // Get user's current locale settings
    private static let locale = Locale.current
    private static let groupingSeparator = locale.groupingSeparator ?? ","
    private static let decimalSeparator = locale.decimalSeparator ?? "."

    /// Formats input text with locale-specific separators as user types
    /// - Parameter input: Raw input string
    /// - Returns: Formatted string with locale-specific separators
    static func formatInput(_ input: String) -> String {
        // Remove all grouping separators first
        var cleanValue = input
        for separator in [",", ".", " ", "'"] {
            if separator != decimalSeparator {
                cleanValue = cleanValue.replacingOccurrences(of: separator, with: "")
            }
        }

        // Only allow digits and the decimal separator
        let allowedChars = "0123456789\(decimalSeparator)"
        let filtered = cleanValue.filter { allowedChars.contains($0) }

        // Split into integer and decimal parts
        let parts = filtered.components(separatedBy: decimalSeparator)

        if parts.count > 2 {
            // Too many decimal separators, keep only first two parts
            let integerPart = addThousandsSeparator(parts[0])
            return integerPart + decimalSeparator + parts[1]
        } else if parts.count == 2 {
            // Has decimal part
            let integerPart = addThousandsSeparator(parts[0])
            let decimalPart = String(parts[1].prefix(2)) // Max 2 decimal places
            return integerPart + (decimalPart.isEmpty ? decimalSeparator : "\(decimalSeparator)\(decimalPart)")
        } else {
            // No decimal part
            return addThousandsSeparator(filtered)
        }
    }

    /// Adds locale-specific thousands separator to integer part
    /// - Parameter string: Integer part as string
    /// - Returns: Formatted string with locale-specific grouping separator
    private static func addThousandsSeparator(_ string: String) -> String {
        // Remove any existing separators
        var cleanString = string
        for separator in [",", ".", " ", "'"] {
            cleanString = cleanString.replacingOccurrences(of: separator, with: "")
        }

        // If empty, return as is
        guard !cleanString.isEmpty else { return string }

        // Convert to number and back with locale-specific thousands separator
        if let number = Int(cleanString) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.locale = locale
            formatter.groupingSeparator = groupingSeparator
            formatter.usesGroupingSeparator = true
            return formatter.string(from: NSNumber(value: number)) ?? cleanString
        }

        return cleanString
    }

    /// Converts formatted string back to Double (locale-aware)
    /// - Parameter formattedString: String with locale-specific separators
    /// - Returns: Double value
    static func parseDouble(_ formattedString: String) -> Double {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal

        // Try parsing with formatter first
        if let number = formatter.number(from: formattedString) {
            return number.doubleValue
        }

        // Fallback: manual parsing
        // Remove all grouping separators
        var cleanString = formattedString
        for separator in [",", ".", " ", "'"] {
            if separator != decimalSeparator {
                cleanString = cleanString.replacingOccurrences(of: separator, with: "")
            }
        }

        // Replace decimal separator with dot for standard parsing
        cleanString = cleanString.replacingOccurrences(of: decimalSeparator, with: ".")

        return Double(cleanString) ?? 0.0
    }

    /// Returns user's locale decimal separator for display purposes
    static var localizedDecimalSeparator: String {
        return decimalSeparator
    }

    /// Returns user's locale grouping separator for display purposes
    static var localizedGroupingSeparator: String {
        return groupingSeparator
    }
}
