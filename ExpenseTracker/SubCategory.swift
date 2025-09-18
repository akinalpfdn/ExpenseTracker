//
//  SubCategory.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI

/// Represents a subcategory that belongs to a parent category
/// Provides granular expense categorization for better tracking and analysis
struct SubCategory: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let categoryId: String
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
        categoryId: String,
        iconName: String = "",
        colorHex: String = "",
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
        self.categoryId = categoryId
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

    /// Returns localized display name for the subcategory
    var displayName: String {
        return L(name)
    }

    /// Returns localized description for the subcategory
    var localizedDescription: String {
        return description.isEmpty ? "" : L(description)
    }

    /// Returns Color object from hex string, falls back to parent category color
    var color: Color {
        if !colorHex.isEmpty {
            return Color(hex: colorHex) ?? .gray
        }
        return .gray // Will be resolved by parent category in practice
    }

    /// Returns the subcategory type if it matches a predefined type
    var subCategoryType: SubCategoryType? {
        return SubCategoryType.allCases.first { $0.rawValue == name }
    }

    // MARK: - Business Logic Methods

    /// Creates a copy of the subcategory with updated properties
    /// - Parameter updates: Dictionary of property updates
    /// - Returns: New SubCategory instance with updated properties
    func updated(with updates: [String: Any]) -> SubCategory {
        return SubCategory(
            id: self.id,
            name: updates["name"] as? String ?? self.name,
            categoryId: updates["categoryId"] as? String ?? self.categoryId,
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

    /// Toggles the active status of the subcategory
    /// - Returns: New SubCategory instance with toggled active status
    func toggleActive() -> SubCategory {
        return updated(with: ["isActive": !isActive])
    }

    /// Updates the budget percentage for this subcategory
    /// - Parameter percentage: New budget percentage (0-100)
    /// - Returns: New SubCategory instance with updated budget percentage
    func withBudgetPercentage(_ percentage: Double) -> SubCategory {
        let clampedPercentage = max(0, min(100, percentage))
        return updated(with: ["budgetPercentage": clampedPercentage])
    }

    // MARK: - Hashable Conformance

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(categoryId)
    }

    static func == (lhs: SubCategory, rhs: SubCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - SubCategoryType Enum

/// Predefined subcategory types organized by parent category
enum SubCategoryType: String, CaseIterable, Identifiable {
    // Food subcategories
    case groceries = "subcategory_groceries"
    case restaurants = "subcategory_restaurants"
    case fastFood = "subcategory_fast_food"
    case coffee = "subcategory_coffee"
    case alcohol = "subcategory_alcohol"

    // Housing subcategories
    case rent = "subcategory_rent"
    case mortgage = "subcategory_mortgage"
    case maintenance = "subcategory_maintenance"
    case furniture = "subcategory_furniture"
    case decorations = "subcategory_decorations"

    // Transportation subcategories
    case fuel = "subcategory_fuel"
    case publicTransport = "subcategory_public_transport"
    case taxi = "subcategory_taxi"
    case carMaintenance = "subcategory_car_maintenance"
    case parking = "subcategory_parking"

    // Health subcategories
    case medical = "subcategory_medical"
    case pharmacy = "subcategory_pharmacy"
    case fitness = "subcategory_fitness"
    case beauty = "subcategory_beauty"
    case mentalHealth = "subcategory_mental_health"

    // Entertainment subcategories
    case movies = "subcategory_movies"
    case music = "subcategory_music"
    case games = "subcategory_games"
    case books = "subcategory_books"
    case hobbies = "subcategory_hobbies"

    // Education subcategories
    case tuition = "subcategory_tuition"
    case courses = "subcategory_courses"
    case supplies = "subcategory_supplies"
    case certification = "subcategory_certification"

    // Shopping subcategories
    case clothing = "subcategory_clothing"
    case electronics = "subcategory_electronics"
    case household = "subcategory_household"
    case gifts = "subcategory_gifts"

    // Work subcategories
    case equipment = "subcategory_equipment"
    case software = "subcategory_software"
    case networking = "subcategory_networking"
    case conferences = "subcategory_conferences"

    // Utilities subcategories
    case electricity = "subcategory_electricity"
    case water = "subcategory_water"
    case gas = "subcategory_gas"
    case internet = "subcategory_internet"
    case phone = "subcategory_phone"

    var id: String { rawValue }

    /// Localized display name
    var displayName: String {
        return L(rawValue)
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        // Food
        case .groceries: return "cart.fill"
        case .restaurants: return "fork.knife.circle.fill"
        case .fastFood: return "takeoutbag.and.cup.and.straw.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .alcohol: return "wineglass.fill"

        // Housing
        case .rent: return "key.fill"
        case .mortgage: return "house.circle.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .furniture: return "chair.fill"
        case .decorations: return "paintbrush.fill"

        // Transportation
        case .fuel: return "fuelpump.fill"
        case .publicTransport: return "bus.fill"
        case .taxi: return "car.side.fill"
        case .carMaintenance: return "wrench.fill"
        case .parking: return "parkingsign"

        // Health
        case .medical: return "stethoscope"
        case .pharmacy: return "pills.fill"
        case .fitness: return "figure.strengthtraining.traditional"
        case .beauty: return "comb.fill"
        case .mentalHealth: return "brain.head.profile"

        // Entertainment
        case .movies: return "tv.and.hifispeaker.fill"
        case .music: return "music.note"
        case .games: return "gamecontroller.fill"
        case .books: return "book.closed.fill"
        case .hobbies: return "paintpalette.fill"

        // Education
        case .tuition: return "graduationcap.fill"
        case .courses: return "studentdesk"
        case .supplies: return "pencil.and.ruler.fill"
        case .certification: return "rosette"

        // Shopping
        case .clothing: return "tshirt.fill"
        case .electronics: return "iphone"
        case .household: return "lightbulb.fill"
        case .gifts: return "gift.fill"

        // Work
        case .equipment: return "desktopcomputer"
        case .software: return "app.badge.fill"
        case .networking: return "person.2.fill"
        case .conferences: return "person.3.fill"

        // Utilities
        case .electricity: return "bolt.fill"
        case .water: return "drop.fill"
        case .gas: return "flame.fill"
        case .internet: return "wifi"
        case .phone: return "phone.fill"
        }
    }

    /// Parent category type
    var parentCategoryType: CategoryType {
        switch self {
        case .groceries, .restaurants, .fastFood, .coffee, .alcohol:
            return .food
        case .rent, .mortgage, .maintenance, .furniture, .decorations:
            return .housing
        case .fuel, .publicTransport, .taxi, .carMaintenance, .parking:
            return .transportation
        case .medical, .pharmacy, .fitness, .beauty, .mentalHealth:
            return .health
        case .movies, .music, .games, .books, .hobbies:
            return .entertainment
        case .tuition, .courses, .supplies, .certification:
            return .education
        case .clothing, .electronics, .household, .gifts:
            return .shopping
        case .equipment, .software, .networking, .conferences:
            return .work
        case .electricity, .water, .gas, .internet, .phone:
            return .utilities
        }
    }

    /// Localized description
    var description: String {
        return L("\(rawValue)_description")
    }

    /// Creates a SubCategory instance from this SubCategoryType
    /// - Parameters:
    ///   - categoryId: ID of the parent category
    ///   - sortOrder: Sort order for the subcategory
    /// - Returns: SubCategory instance with default values
    func toSubCategory(categoryId: String, sortOrder: Int = 0) -> SubCategory {
        return SubCategory(
            name: rawValue,
            categoryId: categoryId,
            iconName: iconName,
            isActive: true,
            sortOrder: sortOrder,
            description: "\(rawValue)_description",
            isDefault: true
        )
    }
}

// MARK: - Default SubCategories Provider

extension SubCategory {
    /// Provides default subcategories for a given category
    /// - Parameter categoryId: ID of the parent category
    /// - Returns: Array of default SubCategory instances for the category
    static func defaultSubCategories(for categoryId: String, categoryType: CategoryType) -> [SubCategory] {
        let relevantTypes = SubCategoryType.allCases.filter { $0.parentCategoryType == categoryType }
        return relevantTypes.enumerated().map { index, subCategoryType in
            subCategoryType.toSubCategory(categoryId: categoryId, sortOrder: index)
        }
    }

    /// Essential subcategories for a category that should always be available
    /// - Parameters:
    ///   - categoryId: ID of the parent category
    ///   - categoryType: Type of the parent category
    /// - Returns: Array of essential SubCategory instances
    static func essentialSubCategories(for categoryId: String, categoryType: CategoryType) -> [SubCategory] {
        let essentialTypes: [SubCategoryType]

        switch categoryType {
        case .food:
            essentialTypes = [.groceries, .restaurants]
        case .housing:
            essentialTypes = [.rent, .maintenance]
        case .transportation:
            essentialTypes = [.fuel, .publicTransport]
        case .health:
            essentialTypes = [.medical, .pharmacy]
        case .entertainment:
            essentialTypes = [.movies, .hobbies]
        case .education:
            essentialTypes = [.tuition, .supplies]
        case .shopping:
            essentialTypes = [.clothing, .household]
        case .work:
            essentialTypes = [.equipment, .software]
        case .utilities:
            essentialTypes = [.electricity, .internet]
        default:
            essentialTypes = []
        }

        return essentialTypes.enumerated().map { index, subCategoryType in
            subCategoryType.toSubCategory(categoryId: categoryId, sortOrder: index)
        }
    }

    /// Creates a custom subcategory
    /// - Parameters:
    ///   - name: SubCategory name (localization key)
    ///   - categoryId: ID of the parent category
    ///   - iconName: SF Symbol name
    ///   - colorHex: Hex color string (optional)
    ///   - budgetPercentage: Recommended budget percentage
    /// - Returns: Custom SubCategory instance
    static func custom(
        name: String,
        categoryId: String,
        iconName: String,
        colorHex: String = "",
        budgetPercentage: Double = 0.0
    ) -> SubCategory {
        return SubCategory(
            name: name,
            categoryId: categoryId,
            iconName: iconName,
            colorHex: colorHex,
            budgetPercentage: budgetPercentage,
            isDefault: false
        )
    }
}

// MARK: - SubCategory Management Extensions

extension Array where Element == SubCategory {
    /// Filters active subcategories
    var activeSubCategories: [SubCategory] {
        return filter { $0.isActive }
    }

    /// Sorts subcategories by sort order
    var sortedByOrder: [SubCategory] {
        return sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Filters subcategories by category ID
    /// - Parameter categoryId: ID of the parent category
    /// - Returns: Array of subcategories belonging to the category
    func subCategories(for categoryId: String) -> [SubCategory] {
        return filter { $0.categoryId == categoryId }
    }

    /// Finds subcategory by name
    /// - Parameter name: SubCategory name to search for
    /// - Returns: SubCategory if found, nil otherwise
    func subCategory(named name: String) -> SubCategory? {
        return first { $0.name == name }
    }

    /// Groups subcategories by category ID
    var groupedByCategory: [String: [SubCategory]] {
        return Dictionary(grouping: self) { $0.categoryId }
    }

    /// Calculates total budget percentage for subcategories in a category
    /// - Parameter categoryId: ID of the parent category
    /// - Returns: Total budget percentage
    func totalBudgetPercentage(for categoryId: String) -> Double {
        return subCategories(for: categoryId).reduce(0) { $0 + $1.budgetPercentage }
    }

    /// Validates that subcategories in a category don't exceed 100% budget
    /// - Parameter categoryId: ID of the parent category
    /// - Returns: True if budget distribution is valid
    func isValidBudgetDistribution(for categoryId: String) -> Bool {
        return totalBudgetPercentage(for: categoryId) <= 100.0
    }

    /// Rebalances budget percentages for subcategories in a category
    /// - Parameter categoryId: ID of the parent category
    /// - Returns: Array of subcategories with rebalanced percentages
    func rebalancedBudgets(for categoryId: String) -> [SubCategory] {
        let categorySubCategories = subCategories(for: categoryId)
        let total = categorySubCategories.reduce(0) { $0 + $1.budgetPercentage }

        guard total > 0 else { return self }

        return map { subCategory in
            if subCategory.categoryId == categoryId {
                let newPercentage = (subCategory.budgetPercentage / total) * 100.0
                return subCategory.withBudgetPercentage(newPercentage)
            } else {
                return subCategory
            }
        }
    }
}