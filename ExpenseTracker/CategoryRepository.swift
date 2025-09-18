//
//  CategoryRepository.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive category repository with business logic and initialization
/// Provides high-level category and subcategory operations with automatic data initialization
/// Uses CategoryDataAccess for Core Data operations and adds business logic layer
@MainActor
class CategoryRepository: ObservableObject {

    // MARK: - Properties

    private let categoryDataAccess: CategoryDataAccess
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    /// Published property for categories
    @Published var categories: [Category] = []

    /// Published property for subcategories
    @Published var subCategories: [SubCategory] = []

    /// Published property for active categories only
    @Published var activeCategories: [Category] = []

    /// Published property for active subcategories only
    @Published var activeSubCategories: [SubCategory] = []

    /// Published property for initialization status
    @Published var isInitialized: Bool = false

    /// Published property for category analytics
    @Published var categoryAnalytics: [CategoryAnalytics] = []

    // MARK: - Initialization

    init(
        categoryDataAccess: CategoryDataAccess = CategoryDataAccess(),
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.categoryDataAccess = categoryDataAccess
        self.settingsManager = settingsManager
        setupBindings()
        initializeIfNeeded()
    }

    // MARK: - Private Setup Methods

    private func setupBindings() {
        // Listen for data changes from the data access layer
        categoryDataAccess.$categories
            .sink { [weak self] categories in
                self?.categories = categories
                self?.updateActiveCategories()
            }
            .store(in: &cancellables)

        categoryDataAccess.$subCategories
            .sink { [weak self] subCategories in
                self?.subCategories = subCategories
                self?.updateActiveSubCategories()
            }
            .store(in: &cancellables)

        // Listen for settings changes that might affect category display
        settingsManager.$preferredLanguage
            .sink { [weak self] _ in
                // Refresh to get updated localized names
                self?.refreshCategories()
            }
            .store(in: &cancellables)
    }

    private func initializeIfNeeded() {
        Task {
            await checkAndInitializeDefaultData()
        }
    }

    // MARK: - Public Methods - Initialization

    /// Checks if default categories exist and creates them if not
    func checkAndInitializeDefaultData() async {
        do {
            let existingCategories = try await categoryDataAccess.getAllCategories(includeInactive: true)

            // If no categories exist, initialize with defaults
            if existingCategories.isEmpty {
                await initializeDefaultCategories()
                await initializeDefaultSubCategories()
            }

            // Check if we need to add any missing default categories
            await ensureAllDefaultCategoriesExist()

            await MainActor.run {
                self.isInitialized = true
            }

            // Update analytics
            await refreshCategoryAnalytics()

        } catch {
            print("Failed to initialize default data: \(error)")
        }
    }

    /// Forces initialization of default categories (useful for reset scenarios)
    func initializeDefaultCategories() async {
        do {
            let defaultCategories = Category.defaultCategories()

            for category in defaultCategories {
                try await categoryDataAccess.createCategory(category)
            }

            settingsManager.triggerHapticFeedback(.light)
        } catch {
            print("Failed to initialize default categories: \(error)")
        }
    }

    /// Initializes default subcategories for all categories
    func initializeDefaultSubCategories() async {
        do {
            let categories = try await categoryDataAccess.getAllCategories()

            for category in categories {
                if let categoryType = CategoryType(rawValue: category.name) {
                    let defaultSubCategories = SubCategory.defaultSubCategories(
                        for: category.id,
                        categoryType: categoryType
                    )

                    for subCategory in defaultSubCategories {
                        try await categoryDataAccess.createSubCategory(subCategory)
                    }
                }
            }

            settingsManager.triggerHapticFeedback(.light)
        } catch {
            print("Failed to initialize default subcategories: \(error)")
        }
    }

    /// Ensures all default categories exist, adding missing ones
    private func ensureAllDefaultCategoriesExist() async {
        do {
            let existingCategories = try await categoryDataAccess.getAllCategories(includeInactive: true)
            let existingNames = Set(existingCategories.map { $0.name })
            let defaultCategories = Category.defaultCategories()

            for defaultCategory in defaultCategories {
                if !existingNames.contains(defaultCategory.name) {
                    try await categoryDataAccess.createCategory(defaultCategory)

                    // Also add default subcategories for this new category
                    if let categoryType = CategoryType(rawValue: defaultCategory.name) {
                        let defaultSubCategories = SubCategory.defaultSubCategories(
                            for: defaultCategory.id,
                            categoryType: categoryType
                        )

                        for subCategory in defaultSubCategories {
                            try await categoryDataAccess.createSubCategory(subCategory)
                        }
                    }
                }
            }
        } catch {
            print("Failed to ensure default categories exist: \(error)")
        }
    }

    // MARK: - Public Methods - Category CRUD

    /// Creates a new category with validation
    /// - Parameter category: The category to create
    /// - Throws: CategoryRepositoryError if validation fails
    func createCategory(_ category: Category) async throws {
        try validateCategory(category)

        // Check for duplicate names
        let existingCategories = try await categoryDataAccess.getAllCategories(includeInactive: true)
        if existingCategories.contains(where: { $0.name.lowercased() == category.name.lowercased() }) {
            throw CategoryRepositoryError.duplicateName
        }

        try await categoryDataAccess.createCategory(category)
        await refreshCategoryAnalytics()
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Updates an existing category
    /// - Parameter category: The updated category
    /// - Throws: CategoryRepositoryError if validation fails
    func updateCategory(_ category: Category) async throws {
        try validateCategory(category)

        // Check for duplicate names (excluding self)
        let existingCategories = try await categoryDataAccess.getAllCategories(includeInactive: true)
        if existingCategories.contains(where: {
            $0.id != category.id && $0.name.lowercased() == category.name.lowercased()
        }) {
            throw CategoryRepositoryError.duplicateName
        }

        try await categoryDataAccess.updateCategory(category)
        await refreshCategoryAnalytics()
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Deletes a category (or deactivates if it has expenses)
    /// - Parameter id: The category ID to delete
    /// - Throws: CategoryRepositoryError if deletion fails
    func deleteCategory(by id: String) async throws {
        // Check if category is used in any active expenses
        let (_, expenseCount) = try await categoryDataAccess.getCategoriesWithExpenseCounts()
            .first { $0.0.id == id } ?? (Category(name: "", iconName: "", colorHex: ""), 0)

        if expenseCount > 0 {
            // Category has expenses, just deactivate it
            guard let category = try await categoryDataAccess.getCategory(by: id) else {
                throw CategoryRepositoryError.categoryNotFound
            }

            let deactivatedCategory = category.toggleActive()
            try await categoryDataAccess.updateCategory(deactivatedCategory)
        } else {
            // Safe to delete completely
            try await categoryDataAccess.deleteCategory(by: id)
        }

        await refreshCategoryAnalytics()
        settingsManager.triggerHapticFeedback(.medium)
    }

    /// Reactivates a deactivated category
    /// - Parameter id: The category ID to reactivate
    /// - Throws: CategoryRepositoryError if category not found
    func reactivateCategory(by id: String) async throws {
        guard let category = try await categoryDataAccess.getCategory(by: id) else {
            throw CategoryRepositoryError.categoryNotFound
        }

        guard !category.isActive else {
            throw CategoryRepositoryError.categoryAlreadyActive
        }

        let reactivatedCategory = category.toggleActive()
        try await categoryDataAccess.updateCategory(reactivatedCategory)
        settingsManager.triggerHapticFeedback(.light)
    }

    // MARK: - Public Methods - SubCategory CRUD

    /// Creates a new subcategory with validation
    /// - Parameter subCategory: The subcategory to create
    /// - Throws: CategoryRepositoryError if validation fails
    func createSubCategory(_ subCategory: SubCategory) async throws {
        try validateSubCategory(subCategory)

        // Check if parent category exists and is active
        guard let parentCategory = try await categoryDataAccess.getCategory(by: subCategory.categoryId),
              parentCategory.isActive else {
            throw CategoryRepositoryError.parentCategoryNotFound
        }

        // Check for duplicate names within the same category
        let existingSubCategories = try await categoryDataAccess.getSubCategories(
            for: subCategory.categoryId,
            includeInactive: true
        )

        if existingSubCategories.contains(where: {
            $0.name.lowercased() == subCategory.name.lowercased()
        }) {
            throw CategoryRepositoryError.duplicateName
        }

        try await categoryDataAccess.createSubCategory(subCategory)
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Updates an existing subcategory
    /// - Parameter subCategory: The updated subcategory
    /// - Throws: CategoryRepositoryError if validation fails
    func updateSubCategory(_ subCategory: SubCategory) async throws {
        try validateSubCategory(subCategory)

        // Check for duplicate names within the same category (excluding self)
        let existingSubCategories = try await categoryDataAccess.getSubCategories(
            for: subCategory.categoryId,
            includeInactive: true
        )

        if existingSubCategories.contains(where: {
            $0.id != subCategory.id && $0.name.lowercased() == subCategory.name.lowercased()
        }) {
            throw CategoryRepositoryError.duplicateName
        }

        try await categoryDataAccess.updateSubCategory(subCategory)
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Deletes a subcategory (or deactivates if it has expenses)
    /// - Parameter id: The subcategory ID to delete
    /// - Throws: CategoryRepositoryError if deletion fails
    func deleteSubCategory(by id: String) async throws {
        // Check if subcategory is used in any active expenses
        guard let subCategory = try await categoryDataAccess.getSubCategory(by: id) else {
            throw CategoryRepositoryError.subCategoryNotFound
        }

        let (_, expenseCount) = try await categoryDataAccess.getSubCategoriesWithExpenseCounts(
            for: subCategory.categoryId
        ).first { $0.0.id == id } ?? (SubCategory(name: "", categoryId: "", iconName: "", colorHex: ""), 0)

        if expenseCount > 0 {
            // SubCategory has expenses, just deactivate it
            let deactivatedSubCategory = subCategory.toggleActive()
            try await categoryDataAccess.updateSubCategory(deactivatedSubCategory)
        } else {
            // Safe to delete completely
            try await categoryDataAccess.deleteSubCategory(by: id)
        }

        settingsManager.triggerHapticFeedback(.medium)
    }

    // MARK: - Public Methods - Retrieval and Search

    /// Gets categories with filtering options
    /// - Parameters:
    ///   - includeInactive: Whether to include inactive categories
    ///   - sortBy: Sort field
    ///   - ascending: Sort direction
    /// - Returns: Array of categories
    func getCategories(
        includeInactive: Bool = false,
        sortBy: CategorySortField = .sortOrder,
        ascending: Bool = true
    ) async throws -> [Category] {
        var categories = try await categoryDataAccess.getAllCategories(includeInactive: includeInactive)

        // Apply sorting
        categories = sortCategories(categories, by: sortBy, ascending: ascending)

        return categories
    }

    /// Gets subcategories for a specific category
    /// - Parameters:
    ///   - categoryId: The parent category ID
    ///   - includeInactive: Whether to include inactive subcategories
    ///   - sortBy: Sort field
    ///   - ascending: Sort direction
    /// - Returns: Array of subcategories
    func getSubCategories(
        for categoryId: String,
        includeInactive: Bool = false,
        sortBy: SubCategorySortField = .sortOrder,
        ascending: Bool = true
    ) async throws -> [SubCategory] {
        var subCategories = try await categoryDataAccess.getSubCategories(
            for: categoryId,
            includeInactive: includeInactive
        )

        // Apply sorting
        subCategories = sortSubCategories(subCategories, by: sortBy, ascending: ascending)

        return subCategories
    }

    /// Searches categories by name with intelligent matching
    /// - Parameter searchText: Search query
    /// - Returns: Array of matching categories
    func searchCategories(_ searchText: String) async throws -> [Category] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return try await getCategories()
        }

        let results = try await categoryDataAccess.searchCategories(by: searchText)

        // Enhance search with localized name matching
        let enhancedResults = enhanceSearchWithLocalizedNames(results, query: searchText)

        return enhancedResults
    }

    /// Searches subcategories by name
    /// - Parameter searchText: Search query
    /// - Returns: Array of matching subcategories
    func searchSubCategories(_ searchText: String) async throws -> [SubCategory] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return try await categoryDataAccess.getAllSubCategories()
        }

        return try await categoryDataAccess.searchSubCategories(by: searchText)
    }

    /// Gets category by ID
    /// - Parameter id: Category ID
    /// - Returns: Category if found, nil otherwise
    func getCategory(by id: String) async throws -> Category? {
        return try await categoryDataAccess.getCategory(by: id)
    }

    /// Gets subcategory by ID
    /// - Parameter id: SubCategory ID
    /// - Returns: SubCategory if found, nil otherwise
    func getSubCategory(by id: String) async throws -> SubCategory? {
        return try await categoryDataAccess.getSubCategory(by: id)
    }

    // MARK: - Public Methods - Budget Management

    /// Updates budget allocations for multiple categories
    /// - Parameter allocations: Dictionary of category ID to budget percentage
    /// - Throws: CategoryRepositoryError if allocations are invalid
    func updateBudgetAllocations(_ allocations: [String: Double]) async throws {
        // Validate total doesn't exceed 100%
        let totalPercentage = allocations.values.reduce(0, +)
        if totalPercentage > 100.0 {
            throw CategoryRepositoryError.budgetExceeds100Percent
        }

        // Update each category
        for (categoryId, percentage) in allocations {
            guard let category = try await categoryDataAccess.getCategory(by: categoryId) else {
                continue
            }

            let updatedCategory = category.withBudgetPercentage(percentage)
            try await categoryDataAccess.updateCategory(updatedCategory)
        }

        await refreshCategoryAnalytics()
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Gets budget allocation analysis
    /// - Returns: BudgetAllocationAnalysis with allocation details
    func getBudgetAllocationAnalysis() async throws -> BudgetAllocationAnalysis {
        let analysisData = try await categoryDataAccess.getBudgetAllocationAnalysis()

        let totalBudgetPercentage = analysisData["totalBudgetPercentage"] as? Double ?? 0
        let categoryCount = analysisData["categoryCount"] as? Int ?? 0
        let isValidDistribution = analysisData["isValidDistribution"] as? Bool ?? false
        let distribution = analysisData["distribution"] as? [[String: Any]] ?? []

        let categoryDistribution = distribution.compactMap { categoryData -> CategoryBudgetDistribution? in
            guard let name = categoryData["name"] as? String,
                  let percentage = categoryData["percentage"] as? Double,
                  let isDefault = categoryData["isDefault"] as? Bool else {
                return nil
            }

            return CategoryBudgetDistribution(
                name: name,
                percentage: percentage,
                isDefault: isDefault
            )
        }

        return BudgetAllocationAnalysis(
            totalBudgetPercentage: totalBudgetPercentage,
            categoryCount: categoryCount,
            isValidDistribution: isValidDistribution,
            categoryDistribution: categoryDistribution,
            currency: settingsManager.currency
        )
    }

    /// Rebalances budget allocations to total 100%
    func rebalanceBudgetAllocations() async throws {
        let categories = try await getCategories()
        let rebalancedCategories = categories.rebalancedBudgets()

        for category in rebalancedCategories {
            try await categoryDataAccess.updateCategory(category)
        }

        await refreshCategoryAnalytics()
        settingsManager.triggerHapticFeedback(.medium)
    }

    // MARK: - Public Methods - Analytics

    /// Gets comprehensive category analytics
    /// - Returns: Array of CategoryAnalytics
    func getCategoryAnalytics() async throws -> [CategoryAnalytics] {
        let categoriesWithCounts = try await categoryDataAccess.getCategoriesWithExpenseCounts()
        let usageStatistics = try await categoryDataAccess.getCategoryUsageStatistics()

        var analytics: [CategoryAnalytics] = []

        for (category, expenseCount) in categoriesWithCounts {
            let analytics = CategoryAnalytics(
                category: category,
                expenseCount: expenseCount,
                isActive: category.isActive,
                budgetPercentage: category.budgetPercentage,
                usage: determineUsageLevel(expenseCount: expenseCount, statistics: usageStatistics)
            )
            analytics.append(analytics)
        }

        return analytics.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    /// Gets category usage statistics
    /// - Returns: CategoryUsageStatistics with usage details
    func getCategoryUsageStatistics() async throws -> CategoryUsageStatistics {
        let statisticsData = try await categoryDataAccess.getCategoryUsageStatistics()

        let totalExpenses = statisticsData["totalExpenses"] as? Int ?? 0
        let averageExpensesPerCategory = statisticsData["averageExpensesPerCategory"] as? Int ?? 0

        var mostUsedCategory: CategoryUsage?
        var leastUsedCategory: CategoryUsage?

        if let mostUsedData = statisticsData["mostUsedCategory"] as? [String: Any],
           let name = mostUsedData["name"] as? String,
           let count = mostUsedData["expenseCount"] as? Int {
            mostUsedCategory = CategoryUsage(name: name, expenseCount: count)
        }

        if let leastUsedData = statisticsData["leastUsedCategory"] as? [String: Any],
           let name = leastUsedData["name"] as? String,
           let count = leastUsedData["expenseCount"] as? Int {
            leastUsedCategory = CategoryUsage(name: name, expenseCount: count)
        }

        return CategoryUsageStatistics(
            totalExpenses: totalExpenses,
            averageExpensesPerCategory: averageExpensesPerCategory,
            mostUsedCategory: mostUsedCategory,
            leastUsedCategory: leastUsedCategory
        )
    }

    // MARK: - Public Methods - Bulk Operations

    /// Updates sort orders for multiple categories
    /// - Parameter updates: Array of (categoryId, sortOrder) tuples
    func updateCategorySortOrders(_ updates: [(String, Int)]) async throws {
        try await categoryDataAccess.updateCategorySortOrders(updates)
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Updates sort orders for multiple subcategories
    /// - Parameter updates: Array of (subCategoryId, sortOrder) tuples
    func updateSubCategorySortOrders(_ updates: [(String, Int)]) async throws {
        try await categoryDataAccess.updateSubCategorySortOrders(updates)
        settingsManager.triggerHapticFeedback(.light)
    }

    /// Bulk activate/deactivate categories
    /// - Parameters:
    ///   - categoryIds: Array of category IDs
    ///   - isActive: New active state
    func updateCategoriesActiveState(_ categoryIds: [String], isActive: Bool) async throws {
        try await categoryDataAccess.updateCategoriesActiveState(categoryIds, isActive: isActive)
        settingsManager.triggerHapticFeedback(.medium)
    }

    // MARK: - Public Methods - Data Management

    /// Refreshes all category data
    func refreshCategories() async {
        // Trigger a reload of category data
        try? await categoryDataAccess.getAllCategories()
        try? await categoryDataAccess.getAllSubCategories()
        await refreshCategoryAnalytics()
    }

    /// Clears all cached data
    func clearCache() {
        categories = []
        subCategories = []
        activeCategories = []
        activeSubCategories = []
        categoryAnalytics = []
    }

    /// Exports category configuration
    /// - Returns: Dictionary containing category configuration
    func exportCategoryConfiguration() async throws -> [String: Any] {
        let categories = try await getCategories(includeInactive: true)
        let subCategories = try await categoryDataAccess.getAllSubCategories(includeInactive: true)

        return [
            "categories": categories.map { categoryToDictionary($0) },
            "subCategories": subCategories.map { subCategoryToDictionary($0) },
            "exportDate": Date(),
            "version": "1.0"
        ]
    }

    /// Imports category configuration
    /// - Parameter configuration: Dictionary containing category configuration
    func importCategoryConfiguration(_ configuration: [String: Any]) async throws {
        guard let categoriesData = configuration["categories"] as? [[String: Any]],
              let subCategoriesData = configuration["subCategories"] as? [[String: Any]] else {
            throw CategoryRepositoryError.invalidImportData
        }

        // Import categories
        for categoryData in categoriesData {
            if let category = categoryFromDictionary(categoryData) {
                do {
                    try await createCategory(category)
                } catch CategoryRepositoryError.duplicateName {
                    // Skip duplicates
                    continue
                } catch {
                    print("Failed to import category: \(error)")
                }
            }
        }

        // Import subcategories
        for subCategoryData in subCategoriesData {
            if let subCategory = subCategoryFromDictionary(subCategoryData) {
                do {
                    try await createSubCategory(subCategory)
                } catch CategoryRepositoryError.duplicateName {
                    // Skip duplicates
                    continue
                } catch {
                    print("Failed to import subcategory: \(error)")
                }
            }
        }

        settingsManager.triggerHapticFeedback(.success)
    }

    // MARK: - Private Methods

    private func validateCategory(_ category: Category) throws {
        guard !category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CategoryRepositoryError.missingName
        }

        guard !category.iconName.isEmpty else {
            throw CategoryRepositoryError.missingIcon
        }

        guard !category.colorHex.isEmpty else {
            throw CategoryRepositoryError.missingColor
        }

        guard category.budgetPercentage >= 0 && category.budgetPercentage <= 100 else {
            throw CategoryRepositoryError.invalidBudgetPercentage
        }
    }

    private func validateSubCategory(_ subCategory: SubCategory) throws {
        guard !subCategory.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CategoryRepositoryError.missingName
        }

        guard !subCategory.categoryId.isEmpty else {
            throw CategoryRepositoryError.missingCategoryId
        }

        guard !subCategory.iconName.isEmpty else {
            throw CategoryRepositoryError.missingIcon
        }

        guard !subCategory.colorHex.isEmpty else {
            throw CategoryRepositoryError.missingColor
        }
    }

    private func updateActiveCategories() {
        activeCategories = categories.filter { $0.isActive }
    }

    private func updateActiveSubCategories() {
        activeSubCategories = subCategories.filter { $0.isActive }
    }

    private func sortCategories(
        _ categories: [Category],
        by sortField: CategorySortField,
        ascending: Bool
    ) -> [Category] {
        return categories.sorted { lhs, rhs in
            let result: Bool
            switch sortField {
            case .name:
                result = lhs.displayName < rhs.displayName
            case .sortOrder:
                result = lhs.sortOrder < rhs.sortOrder
            case .budgetPercentage:
                result = lhs.budgetPercentage < rhs.budgetPercentage
            case .createdAt:
                result = lhs.createdAt < rhs.createdAt
            }
            return ascending ? result : !result
        }
    }

    private func sortSubCategories(
        _ subCategories: [SubCategory],
        by sortField: SubCategorySortField,
        ascending: Bool
    ) -> [SubCategory] {
        return subCategories.sorted { lhs, rhs in
            let result: Bool
            switch sortField {
            case .name:
                result = lhs.displayName < rhs.displayName
            case .sortOrder:
                result = lhs.sortOrder < rhs.sortOrder
            case .createdAt:
                result = lhs.createdAt < rhs.createdAt
            }
            return ascending ? result : !result
        }
    }

    private func enhanceSearchWithLocalizedNames(_ results: [Category], query: String) -> [Category] {
        let lowercaseQuery = query.lowercased()

        // Add categories whose localized names match the query
        let additionalMatches = categories.filter { category in
            let localizedName = category.displayName.lowercased()
            return localizedName.contains(lowercaseQuery) && !results.contains(category)
        }

        return (results + additionalMatches).sorted { $0.sortOrder < $1.sortOrder }
    }

    private func determineUsageLevel(expenseCount: Int, statistics: [String: Any]) -> CategoryUsageLevel {
        let averageExpenses = statistics["averageExpensesPerCategory"] as? Int ?? 0

        if expenseCount == 0 {
            return .unused
        } else if expenseCount < averageExpenses / 2 {
            return .low
        } else if expenseCount > averageExpenses * 2 {
            return .high
        } else {
            return .medium
        }
    }

    private func refreshCategoryAnalytics() async {
        do {
            let analytics = try await getCategoryAnalytics()
            await MainActor.run {
                self.categoryAnalytics = analytics
            }
        } catch {
            print("Failed to refresh category analytics: \(error)")
        }
    }

    private func categoryToDictionary(_ category: Category) -> [String: Any] {
        return [
            "id": category.id,
            "name": category.name,
            "iconName": category.iconName,
            "colorHex": category.colorHex,
            "isActive": category.isActive,
            "sortOrder": category.sortOrder,
            "description": category.description,
            "budgetPercentage": category.budgetPercentage,
            "isDefault": category.isDefault,
            "createdAt": category.createdAt,
            "updatedAt": category.updatedAt
        ]
    }

    private func subCategoryToDictionary(_ subCategory: SubCategory) -> [String: Any] {
        return [
            "id": subCategory.id,
            "name": subCategory.name,
            "categoryId": subCategory.categoryId,
            "iconName": subCategory.iconName,
            "colorHex": subCategory.colorHex,
            "isActive": subCategory.isActive,
            "sortOrder": subCategory.sortOrder,
            "description": subCategory.description,
            "isDefault": subCategory.isDefault,
            "createdAt": subCategory.createdAt,
            "updatedAt": subCategory.updatedAt
        ]
    }

    private func categoryFromDictionary(_ data: [String: Any]) -> Category? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let iconName = data["iconName"] as? String,
              let colorHex = data["colorHex"] as? String else {
            return nil
        }

        return Category(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            isActive: data["isActive"] as? Bool ?? true,
            sortOrder: data["sortOrder"] as? Int ?? 0,
            description: data["description"] as? String ?? "",
            budgetPercentage: data["budgetPercentage"] as? Double ?? 0.0,
            isDefault: data["isDefault"] as? Bool ?? false,
            createdAt: data["createdAt"] as? Date ?? Date(),
            updatedAt: data["updatedAt"] as? Date ?? Date()
        )
    }

    private func subCategoryFromDictionary(_ data: [String: Any]) -> SubCategory? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String,
              let categoryId = data["categoryId"] as? String,
              let iconName = data["iconName"] as? String,
              let colorHex = data["colorHex"] as? String else {
            return nil
        }

        return SubCategory(
            id: id,
            name: name,
            categoryId: categoryId,
            iconName: iconName,
            colorHex: colorHex,
            isActive: data["isActive"] as? Bool ?? true,
            sortOrder: data["sortOrder"] as? Int ?? 0,
            description: data["description"] as? String ?? "",
            isDefault: data["isDefault"] as? Bool ?? false,
            createdAt: data["createdAt"] as? Date ?? Date(),
            updatedAt: data["updatedAt"] as? Date ?? Date()
        )
    }
}

// MARK: - Supporting Types

/// Category repository specific errors
enum CategoryRepositoryError: LocalizedError {
    case missingName
    case missingIcon
    case missingColor
    case missingCategoryId
    case invalidBudgetPercentage
    case duplicateName
    case categoryNotFound
    case subCategoryNotFound
    case parentCategoryNotFound
    case categoryAlreadyActive
    case budgetExceeds100Percent
    case invalidImportData

    var errorDescription: String? {
        switch self {
        case .missingName:
            return L("error_missing_name")
        case .missingIcon:
            return L("error_missing_icon")
        case .missingColor:
            return L("error_missing_color")
        case .missingCategoryId:
            return L("error_missing_category_id")
        case .invalidBudgetPercentage:
            return L("error_invalid_budget_percentage")
        case .duplicateName:
            return L("error_duplicate_name")
        case .categoryNotFound:
            return L("error_category_not_found")
        case .subCategoryNotFound:
            return L("error_subcategory_not_found")
        case .parentCategoryNotFound:
            return L("error_parent_category_not_found")
        case .categoryAlreadyActive:
            return L("error_category_already_active")
        case .budgetExceeds100Percent:
            return L("error_budget_exceeds_100_percent")
        case .invalidImportData:
            return L("error_invalid_import_data")
        }
    }
}

/// Category sort fields
enum CategorySortField: String, CaseIterable {
    case name = "name"
    case sortOrder = "sortOrder"
    case budgetPercentage = "budgetPercentage"
    case createdAt = "createdAt"

    var displayName: String {
        switch self {
        case .name:
            return L("sort_by_name")
        case .sortOrder:
            return L("sort_by_order")
        case .budgetPercentage:
            return L("sort_by_budget")
        case .createdAt:
            return L("sort_by_created")
        }
    }
}

/// SubCategory sort fields
enum SubCategorySortField: String, CaseIterable {
    case name = "name"
    case sortOrder = "sortOrder"
    case createdAt = "createdAt"

    var displayName: String {
        switch self {
        case .name:
            return L("sort_by_name")
        case .sortOrder:
            return L("sort_by_order")
        case .createdAt:
            return L("sort_by_created")
        }
    }
}

/// Category usage levels
enum CategoryUsageLevel {
    case unused
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .unused:
            return L("usage_unused")
        case .low:
            return L("usage_low")
        case .medium:
            return L("usage_medium")
        case .high:
            return L("usage_high")
        }
    }

    var color: Color {
        switch self {
        case .unused:
            return .gray
        case .low:
            return .yellow
        case .medium:
            return .green
        case .high:
            return .blue
        }
    }
}

/// Category analytics data
struct CategoryAnalytics {
    let category: Category
    let expenseCount: Int
    let isActive: Bool
    let budgetPercentage: Double
    let usage: CategoryUsageLevel
}

/// Budget allocation analysis
struct BudgetAllocationAnalysis {
    let totalBudgetPercentage: Double
    let categoryCount: Int
    let isValidDistribution: Bool
    let categoryDistribution: [CategoryBudgetDistribution]
    let currency: String

    var remainingPercentage: Double {
        return max(100.0 - totalBudgetPercentage, 0)
    }

    var isOverAllocated: Bool {
        return totalBudgetPercentage > 100.0
    }
}

/// Category budget distribution
struct CategoryBudgetDistribution {
    let name: String
    let percentage: Double
    let isDefault: Bool
}

/// Category usage statistics
struct CategoryUsageStatistics {
    let totalExpenses: Int
    let averageExpensesPerCategory: Int
    let mostUsedCategory: CategoryUsage?
    let leastUsedCategory: CategoryUsage?
}

/// Category usage data
struct CategoryUsage {
    let name: String
    let expenseCount: Int
}

// MARK: - Preview Helper

#if DEBUG
extension CategoryRepository {
    static let preview: CategoryRepository = {
        return CategoryRepository(
            categoryDataAccess: CategoryDataAccess.preview,
            settingsManager: SettingsManager.preview
        )
    }()
}
#endif