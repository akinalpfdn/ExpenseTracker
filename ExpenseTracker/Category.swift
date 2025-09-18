//
//  Category.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI

/// Represents an expense category with comprehensive metadata and localization support
/// Replaces Kotlin Category entity with Swift-friendly implementation using SF Symbols
struct Category: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let iconName: String
    let colorHex: String
    let isActive: Bool
    let sortOrder: Int
    let description: String
    let budgetPercentage: Double
    let isDefault: Bool
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        name: String,
        iconName: String,
        colorHex: String,
        isActive: Bool = true,
        sortOrder: Int = 0,
        description: String = "",
        budgetPercentage: Double = 0.0,
        isDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.description = description
        self.budgetPercentage = budgetPercentage
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns localized display name for the category
    var displayName: String {
        return L(name)
    }

    /// Returns localized description for the category
    var localizedDescription: String {
        return description.isEmpty ? "" : L(description)
    }

    /// Returns Color object from hex string
    var color: Color {
        return Color(hex: colorHex) ?? .gray
    }

    /// Returns the category as a CategoryType enum if it matches
    var categoryType: CategoryType? {
        return CategoryType.allCases.first { $0.rawValue == name }
    }

    // MARK: - Business Logic Methods

    /// Creates a copy of the category with updated properties
    /// - Parameter updates: Dictionary of property updates
    /// - Returns: New Category instance with updated properties
    func updated(with updates: [String: Any]) -> Category {
        return Category(
            id: self.id,
            name: updates["name"] as? String ?? self.name,
            iconName: updates["iconName"] as? String ?? self.iconName,
            colorHex: updates["colorHex"] as? String ?? self.colorHex,
            isActive: updates["isActive"] as? Bool ?? self.isActive,
            sortOrder: updates["sortOrder"] as? Int ?? self.sortOrder,
            description: updates["description"] as? String ?? self.description,
            budgetPercentage: updates["budgetPercentage"] as? Double ?? self.budgetPercentage,
            isDefault: self.isDefault,
            createdAt: self.createdAt,
            updatedAt: Date()
        )
    }

    /// Toggles the active status of the category
    /// - Returns: New Category instance with toggled active status
    func toggleActive() -> Category {
        return updated(with: ["isActive": !isActive])
    }

    /// Updates the budget percentage for this category
    /// - Parameter percentage: New budget percentage (0-100)
    /// - Returns: New Category instance with updated budget percentage
    func withBudgetPercentage(_ percentage: Double) -> Category {
        let clampedPercentage = max(0, min(100, percentage))
        return updated(with: ["budgetPercentage": clampedPercentage])
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(iconName)
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - CategoryType Enum

/// Predefined category types with localized names and SF Symbols
enum CategoryType: String, CaseIterable, Identifiable {
    case food = "category_food"
    case housing = "category_housing"
    case transportation = "category_transportation"
    case health = "category_health"
    case entertainment = "category_entertainment"
    case education = "category_education"
    case shopping = "category_shopping"
    case pets = "category_pets"
    case work = "category_work"
    case tax = "category_tax"
    case donations = "category_donations"
    case savings = "category_savings"
    case utilities = "category_utilities"
    case insurance = "category_insurance"
    case travel = "category_travel"

    var id: String { rawValue }

    /// Localized display name
    var displayName: String {
        return L(rawValue)
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .food:
            return "fork.knife"
        case .housing:
            return "house.fill"
        case .transportation:
            return "car.fill"
        case .health:
            return "heart.fill"
        case .entertainment:
            return "tv.fill"
        case .education:
            return "book.fill"
        case .shopping:
            return "bag.fill"
        case .pets:
            return "pawprint.fill"
        case .work:
            return "briefcase.fill"
        case .tax:
            return "doc.text.fill"
        case .donations:
            return "heart.circle.fill"
        case .savings:
            return "banknote.fill"
        case .utilities:
            return "bolt.fill"
        case .insurance:
            return "shield.fill"
        case .travel:
            return "airplane"
        }
    }

    /// Default color hex string
    var defaultColorHex: String {
        switch self {
        case .food:
            return "#FF6B6B"
        case .housing:
            return "#4ECDC4"
        case .transportation:
            return "#45B7D1"
        case .health:
            return "#96CEB4"
        case .entertainment:
            return "#FECA57"
        case .education:
            return "#6C5CE7"
        case .shopping:
            return "#FD79A8"
        case .pets:
            return "#FDCB6E"
        case .work:
            return "#6C5CE7"
        case .tax:
            return "#636E72"
        case .donations:
            return "#E17055"
        case .savings:
            return "#00B894"
        case .utilities:
            return "#FFEAA7"
        case .insurance:
            return "#81ECEC"
        case .travel:
            return "#74B9FF"
        }
    }

    /// Default budget percentage recommendation
    var defaultBudgetPercentage: Double {
        switch self {
        case .food:
            return 15.0
        case .housing:
            return 30.0
        case .transportation:
            return 15.0
        case .health:
            return 5.0
        case .entertainment:
            return 10.0
        case .education:
            return 5.0
        case .shopping:
            return 5.0
        case .pets:
            return 3.0
        case .work:
            return 2.0
        case .tax:
            return 10.0
        case .donations:
            return 5.0
        case .savings:
            return 20.0
        case .utilities:
            return 10.0
        case .insurance:
            return 5.0
        case .travel:
            return 5.0
        }
    }

    /// Localized description
    var description: String {
        return L("\(rawValue)_description")
    }

    /// Creates a Category instance from this CategoryType
    /// - Parameter sortOrder: Sort order for the category
    /// - Returns: Category instance with default values
    func toCategory(sortOrder: Int = 0) -> Category {
        return Category(
            name: rawValue,
            iconName: iconName,
            colorHex: defaultColorHex,
            isActive: true,
            sortOrder: sortOrder,
            description: "\(rawValue)_description",
            budgetPercentage: defaultBudgetPercentage,
            isDefault: true
        )
    }
}

// MARK: - Default Categories Provider

extension Category {
    /// Provides default categories for initial app setup
    /// - Returns: Array of default Category instances
    static func defaultCategories() -> [Category] {
        return CategoryType.allCases.enumerated().map { index, categoryType in
            categoryType.toCategory(sortOrder: index)
        }
    }

    /// Essential categories that should always be available
    /// - Returns: Array of essential Category instances
    static func essentialCategories() -> [Category] {
        let essentialTypes: [CategoryType] = [.food, .housing, .transportation, .health, .savings]
        return essentialTypes.enumerated().map { index, categoryType in
            categoryType.toCategory(sortOrder: index)
        }
    }

    /// Creates a custom category
    /// - Parameters:
    ///   - name: Category name (localization key)
    ///   - iconName: SF Symbol name
    ///   - colorHex: Hex color string
    ///   - budgetPercentage: Recommended budget percentage
    /// - Returns: Custom Category instance
    static func custom(
        name: String,
        iconName: String,
        colorHex: String,
        budgetPercentage: Double = 0.0
    ) -> Category {
        return Category(
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            budgetPercentage: budgetPercentage,
            isDefault: false
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: Hex color string (with or without #)
    /// - Returns: Color instance or nil if invalid hex
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Converts Color to hex string
    /// - Returns: Hex representation of the color
    var hexString: String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Category Management Extensions

extension Array where Element == Category {
    /// Filters active categories
    var activeCategories: [Category] {
        return filter { $0.isActive }
    }

    /// Sorts categories by sort order
    var sortedByOrder: [Category] {
        return sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Finds category by name
    /// - Parameter name: Category name to search for
    /// - Returns: Category if found, nil otherwise
    func category(named name: String) -> Category? {
        return first { $0.name == name }
    }

    /// Calculates total budget percentage
    var totalBudgetPercentage: Double {
        return reduce(0) { $0 + $1.budgetPercentage }
    }

    /// Validates that total budget percentage doesn't exceed 100%
    var isValidBudgetDistribution: Bool {
        return totalBudgetPercentage <= 100.0
    }

    /// Rebalances budget percentages to total 100%
    /// - Returns: Array of categories with rebalanced percentages
    func rebalancedBudgets() -> [Category] {
        let total = totalBudgetPercentage
        guard total > 0 else { return self }

        return map { category in
            let newPercentage = (category.budgetPercentage / total) * 100.0
            return category.withBudgetPercentage(newPercentage)
        }
    }
}