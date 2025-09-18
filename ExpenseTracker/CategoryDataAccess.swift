//
//  CategoryDataAccess.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData
import Combine

/// Data access layer for Category and SubCategory entities
/// Provides comprehensive CRUD operations, queries, and business logic
@MainActor
class CategoryDataAccess: ObservableObject {

    // MARK: - Properties

    private let coreDataStack: CoreDataStack

    /// Published property for categories to notify SwiftUI views
    @Published var categories: [Category] = []

    /// Published property for subcategories to notify SwiftUI views
    @Published var subCategories: [SubCategory] = []

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadCategories()
        loadSubCategories()
    }

    // MARK: - Category CRUD Operations

    /// Creates a new category
    /// - Parameter category: The category to create
    /// - Throws: Core Data error if creation fails
    func createCategory(_ category: Category) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let cdCategory = CDCategory.from(category, context: context)

            // Set up relationships if this category has a parent in the category type
            if let categoryType = CategoryType(rawValue: category.name) {
                // Create default subcategories for this category
                let defaultSubCategories = SubCategory.defaultSubCategories(for: category.id, categoryType: categoryType)
                for subCategory in defaultSubCategories {
                    let cdSubCategory = CDSubCategory.from(subCategory, context: context)
                    cdCategory.addToSubCategories(cdSubCategory)
                }
            }
        }

        await loadCategories()
        await loadSubCategories()
    }

    /// Retrieves a category by ID
    /// - Parameter id: The category ID
    /// - Returns: Category if found, nil otherwise
    /// - Throws: Core Data error if fetch fails
    func getCategory(by id: String) async throws -> Category? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            let results = try context.fetch(request)
            return results.first?.toCategory()
        }
    }

    /// Retrieves all categories
    /// - Parameter includeInactive: Whether to include inactive categories
    /// - Returns: Array of categories
    /// - Throws: Core Data error if fetch fails
    func getAllCategories(includeInactive: Bool = false) async throws -> [Category] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()

            if !includeInactive {
                request.predicate = NSPredicate(format: "isActive == YES")
            }

            request.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let results = try context.fetch(request)
            return results.map { $0.toCategory() }
        }
    }

    /// Updates an existing category
    /// - Parameter category: The updated category
    /// - Throws: Core Data error if update fails
    func updateCategory(_ category: Category) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", category.id)
            request.fetchLimit = 1

            guard let cdCategory = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            cdCategory.update(from: category)
        }

        await loadCategories()
    }

    /// Deletes a category and all its subcategories
    /// - Parameter id: The category ID to delete
    /// - Throws: Core Data error if deletion fails
    func deleteCategory(by id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            guard let cdCategory = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            // Check if there are any expenses in this category
            let expenseRequest: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            expenseRequest.predicate = NSPredicate(format: "categoryId == %@", id)
            let expenseCount = try context.count(for: expenseRequest)

            if expenseCount > 0 {
                // Don't delete categories with expenses, just deactivate them
                cdCategory.isActive = false
                cdCategory.updatedAt = Date()
            } else {
                // Safe to delete as no expenses reference this category
                context.delete(cdCategory)
            }
        }

        await loadCategories()
        await loadSubCategories()
    }

    // MARK: - SubCategory CRUD Operations

    /// Creates a new subcategory
    /// - Parameter subCategory: The subcategory to create
    /// - Throws: Core Data error if creation fails
    func createSubCategory(_ subCategory: SubCategory) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let cdSubCategory = CDSubCategory.from(subCategory, context: context)

            // Set up relationship with parent category
            let categoryRequest: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", subCategory.categoryId)
            categoryRequest.fetchLimit = 1

            if let parentCategory = try context.fetch(categoryRequest).first {
                cdSubCategory.category = parentCategory
                parentCategory.addToSubCategories(cdSubCategory)
            }
        }

        await loadSubCategories()
    }

    /// Retrieves a subcategory by ID
    /// - Parameter id: The subcategory ID
    /// - Returns: SubCategory if found, nil otherwise
    /// - Throws: Core Data error if fetch fails
    func getSubCategory(by id: String) async throws -> SubCategory? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            let results = try context.fetch(request)
            return results.first?.toSubCategory()
        }
    }

    /// Retrieves subcategories for a specific category
    /// - Parameters:
    ///   - categoryId: The parent category ID
    ///   - includeInactive: Whether to include inactive subcategories
    /// - Returns: Array of subcategories
    /// - Throws: Core Data error if fetch fails
    func getSubCategories(for categoryId: String, includeInactive: Bool = false) async throws -> [SubCategory] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()

            var predicates = [NSPredicate(format: "categoryId == %@", categoryId)]
            if !includeInactive {
                predicates.append(NSPredicate(format: "isActive == YES"))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let results = try context.fetch(request)
            return results.map { $0.toSubCategory() }
        }
    }

    /// Retrieves all subcategories
    /// - Parameter includeInactive: Whether to include inactive subcategories
    /// - Returns: Array of subcategories
    /// - Throws: Core Data error if fetch fails
    func getAllSubCategories(includeInactive: Bool = false) async throws -> [SubCategory] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()

            if !includeInactive {
                request.predicate = NSPredicate(format: "isActive == YES")
            }

            request.sortDescriptors = [
                NSSortDescriptor(key: "categoryId", ascending: true),
                NSSortDescriptor(key: "sortOrder", ascending: true),
                NSSortDescriptor(key: "name", ascending: true)
            ]

            let results = try context.fetch(request)
            return results.map { $0.toSubCategory() }
        }
    }

    /// Updates an existing subcategory
    /// - Parameter subCategory: The updated subcategory
    /// - Throws: Core Data error if update fails
    func updateSubCategory(_ subCategory: SubCategory) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", subCategory.id)
            request.fetchLimit = 1

            guard let cdSubCategory = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            cdSubCategory.update(from: subCategory)
        }

        await loadSubCategories()
    }

    /// Deletes a subcategory
    /// - Parameter id: The subcategory ID to delete
    /// - Throws: Core Data error if deletion fails
    func deleteSubCategory(by id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            guard let cdSubCategory = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            // Check if there are any expenses in this subcategory
            let expenseRequest: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
            expenseRequest.predicate = NSPredicate(format: "subCategoryId == %@", id)
            let expenseCount = try context.count(for: expenseRequest)

            if expenseCount > 0 {
                // Don't delete subcategories with expenses, just deactivate them
                cdSubCategory.isActive = false
                cdSubCategory.updatedAt = Date()
            } else {
                // Safe to delete as no expenses reference this subcategory
                context.delete(cdSubCategory)
            }
        }

        await loadSubCategories()
    }

    // MARK: - Search and Filter Operations

    /// Searches categories by name
    /// - Parameter searchText: The search term
    /// - Returns: Array of matching categories
    /// - Throws: Core Data error if search fails
    func searchCategories(by searchText: String) async throws -> [Category] {
        guard !searchText.isEmpty else {
            return try await getAllCategories()
        }

        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ AND isActive == YES", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try context.fetch(request)
            return results.map { $0.toCategory() }
        }
    }

    /// Searches subcategories by name
    /// - Parameter searchText: The search term
    /// - Returns: Array of matching subcategories
    /// - Throws: Core Data error if search fails
    func searchSubCategories(by searchText: String) async throws -> [SubCategory] {
        guard !searchText.isEmpty else {
            return try await getAllSubCategories()
        }

        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@ AND isActive == YES", searchText)
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let results = try context.fetch(request)
            return results.map { $0.toSubCategory() }
        }
    }

    /// Gets categories with their expense counts
    /// - Returns: Array of tuples with category and expense count
    /// - Throws: Core Data error if fetch fails
    func getCategoriesWithExpenseCounts() async throws -> [(Category, Int)] {
        return try await coreDataStack.performBackgroundTask { context in
            let categoryRequest: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "isActive == YES")
            categoryRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

            let categories = try context.fetch(categoryRequest)
            var results: [(Category, Int)] = []

            for cdCategory in categories {
                let expenseRequest: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
                expenseRequest.predicate = NSPredicate(format: "categoryId == %@", cdCategory.id ?? "")
                let expenseCount = try context.count(for: expenseRequest)

                results.append((cdCategory.toCategory(), expenseCount))
            }

            return results
        }
    }

    /// Gets subcategories with their expense counts for a category
    /// - Parameter categoryId: The parent category ID
    /// - Returns: Array of tuples with subcategory and expense count
    /// - Throws: Core Data error if fetch fails
    func getSubCategoriesWithExpenseCounts(for categoryId: String) async throws -> [(SubCategory, Int)] {
        return try await coreDataStack.performBackgroundTask { context in
            let subCategoryRequest: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
            subCategoryRequest.predicate = NSPredicate(format: "categoryId == %@ AND isActive == YES", categoryId)
            subCategoryRequest.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

            let subCategories = try context.fetch(subCategoryRequest)
            var results: [(SubCategory, Int)] = []

            for cdSubCategory in subCategories {
                let expenseRequest: NSFetchRequest<CDExpense> = CDExpense.fetchRequest()
                expenseRequest.predicate = NSPredicate(format: "subCategoryId == %@", cdSubCategory.id ?? "")
                let expenseCount = try context.count(for: expenseRequest)

                results.append((cdSubCategory.toSubCategory(), expenseCount))
            }

            return results
        }
    }

    // MARK: - Bulk Operations

    /// Updates the sort order for multiple categories
    /// - Parameter categoriesWithOrders: Array of tuples with category ID and new sort order
    /// - Throws: Core Data error if update fails
    func updateCategorySortOrders(_ categoriesWithOrders: [(String, Int)]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (categoryId, sortOrder) in categoriesWithOrders {
                let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", categoryId)
                request.fetchLimit = 1

                if let cdCategory = try context.fetch(request).first {
                    cdCategory.sortOrder = Int32(sortOrder)
                    cdCategory.updatedAt = Date()
                }
            }
        }

        await loadCategories()
    }

    /// Updates the sort order for multiple subcategories
    /// - Parameter subCategoriesWithOrders: Array of tuples with subcategory ID and new sort order
    /// - Throws: Core Data error if update fails
    func updateSubCategorySortOrders(_ subCategoriesWithOrders: [(String, Int)]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            for (subCategoryId, sortOrder) in subCategoriesWithOrders {
                let request: NSFetchRequest<CDSubCategory> = CDSubCategory.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", subCategoryId)
                request.fetchLimit = 1

                if let cdSubCategory = try context.fetch(request).first {
                    cdSubCategory.sortOrder = Int32(sortOrder)
                    cdSubCategory.updatedAt = Date()
                }
            }
        }

        await loadSubCategories()
    }

    /// Activates or deactivates multiple categories
    /// - Parameters:
    ///   - categoryIds: Array of category IDs
    ///   - isActive: New active state
    /// - Throws: Core Data error if update fails
    func updateCategoriesActiveState(_ categoryIds: [String], isActive: Bool) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", categoryIds)

            let categories = try context.fetch(request)
            for category in categories {
                category.isActive = isActive
                category.updatedAt = Date()
            }
        }

        await loadCategories()
    }

    // MARK: - Data Loading

    /// Loads categories from Core Data into the published property
    private func loadCategories() {
        Task {
            do {
                let loadedCategories = try await getAllCategories()
                await MainActor.run {
                    self.categories = loadedCategories
                }
            } catch {
                print("Failed to load categories: \(error)")
            }
        }
    }

    /// Loads subcategories from Core Data into the published property
    private func loadSubCategories() {
        Task {
            do {
                let loadedSubCategories = try await getAllSubCategories()
                await MainActor.run {
                    self.subCategories = loadedSubCategories
                }
            } catch {
                print("Failed to load subcategories: \(error)")
            }
        }
    }

    // MARK: - Analytics and Reporting

    /// Gets budget allocation analysis for categories
    /// - Returns: Dictionary with allocation analysis
    /// - Throws: Core Data error if calculation fails
    func getBudgetAllocationAnalysis() async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES")

            let categories = try context.fetch(request)
            let totalBudgetPercentage = categories.reduce(0.0) { $0 + $1.budgetPercentage }
            let categoryCount = categories.count

            let budgetDistribution = categories.map { category in
                [
                    "name": category.name ?? "",
                    "percentage": category.budgetPercentage,
                    "isDefault": category.isDefault
                ]
            }

            return [
                "totalBudgetPercentage": totalBudgetPercentage,
                "categoryCount": categoryCount,
                "isValidDistribution": totalBudgetPercentage <= 100.0,
                "distribution": budgetDistribution
            ]
        }
    }

    /// Gets the most and least used categories
    /// - Returns: Dictionary with usage statistics
    /// - Throws: Core Data error if calculation fails
    func getCategoryUsageStatistics() async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let categoriesWithCounts = try self.getCategoriesWithExpenseCounts()

            let mostUsed = categoriesWithCounts.max { $0.1 < $1.1 }
            let leastUsed = categoriesWithCounts.min { $0.1 < $1.1 }
            let totalExpenses = categoriesWithCounts.reduce(0) { $0 + $1.1 }
            let averageExpensesPerCategory = totalExpenses / max(categoriesWithCounts.count, 1)

            return [
                "totalExpenses": totalExpenses,
                "averageExpensesPerCategory": averageExpensesPerCategory,
                "mostUsedCategory": mostUsed != nil ? [
                    "name": mostUsed!.0.name,
                    "expenseCount": mostUsed!.1
                ] : nil,
                "leastUsedCategory": leastUsed != nil ? [
                    "name": leastUsed!.0.name,
                    "expenseCount": leastUsed!.1
                ] : nil
            ]
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CategoryDataAccess {
    static let preview: CategoryDataAccess = {
        return CategoryDataAccess(coreDataStack: CoreDataStack.preview)
    }()
}
#endif