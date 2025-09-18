//
//  CoreDataStack.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData
import Combine

/// Core Data stack manager with persistence container, context management, and initialization
/// Replaces Room database from Android with Core Data implementation
@MainActor
class CoreDataStack: ObservableObject {

    // MARK: - Properties

    /// Shared singleton instance
    static let shared = CoreDataStack()

    /// Published property to notify SwiftUI views of data changes
    @Published var hasInitialized = false

    /// The persistent container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseTracker")

        // Configure persistent store description
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldInferMappingModelAutomatically = true
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
                fatalError("Failed to load Core Data stack: \(error)")
            }

            // Configure merge policies
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            // Initialize default data if needed
            Task { @MainActor in
                await self?.initializeDefaultDataIfNeeded()
                self?.hasInitialized = true
            }
        }

        return container
    }()

    /// Main context for UI operations (runs on main queue)
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    /// Background context for data operations
    var backgroundContext: NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Initialization

    private init() {
        // Configure notification observers
        setupNotificationObservers()
    }

    // MARK: - Context Management

    /// Saves the view context with error handling
    /// - Throws: Core Data error if save fails
    func saveViewContext() throws {
        guard viewContext.hasChanges else { return }

        do {
            try viewContext.save()
        } catch {
            print("Failed to save view context: \(error)")
            throw CoreDataError.saveError(error)
        }
    }

    /// Saves a background context with error handling
    /// - Parameter context: The background context to save
    /// - Throws: Core Data error if save fails
    func saveBackgroundContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print("Failed to save background context: \(error)")
            throw CoreDataError.saveError(error)
        }
    }

    /// Performs a task on a background context with automatic saving
    /// - Parameter task: The task to perform on the background context
    /// - Returns: The result of the task
    /// - Throws: Any error thrown by the task or save operation
    func performBackgroundTask<T>(_ task: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let context = backgroundContext
            context.perform {
                do {
                    let result = try task(context)
                    try self.saveBackgroundContext(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Performs a task on a background context without returning a value
    /// - Parameter task: The task to perform on the background context
    /// - Throws: Any error thrown by the task or save operation
    func performBackgroundTask(_ task: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let context = backgroundContext
            context.perform {
                do {
                    try task(context)
                    try self.saveBackgroundContext(context)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Data Initialization

    /// Initializes default categories and subcategories if the database is empty
    private func initializeDefaultDataIfNeeded() async {
        do {
            let categoryCount = try await performBackgroundTask { context in
                let request: NSFetchRequest<CDCategory> = CDCategory.fetchRequest()
                return try context.count(for: request)
            }

            if categoryCount == 0 {
                print("Initializing default categories and subcategories...")
                try await initializeDefaultCategories()
            }
        } catch {
            print("Failed to check for existing categories: \(error)")
        }
    }

    /// Creates default categories and their subcategories
    private func initializeDefaultCategories() async throws {
        try await performBackgroundTask { context in
            let defaultCategories = Category.defaultCategories()

            for (index, category) in defaultCategories.enumerated() {
                let cdCategory = CDCategory(context: context)
                cdCategory.id = category.id
                cdCategory.name = category.name
                cdCategory.iconName = category.iconName
                cdCategory.colorHex = category.colorHex
                cdCategory.isActive = category.isActive
                cdCategory.sortOrder = Int32(category.sortOrder)
                cdCategory.categoryDescription = category.description
                cdCategory.budgetPercentage = category.budgetPercentage
                cdCategory.isDefault = category.isDefault
                cdCategory.createdAt = category.createdAt
                cdCategory.updatedAt = category.updatedAt

                // Create default subcategories for this category
                if let categoryType = CategoryType(rawValue: category.name) {
                    let defaultSubCategories = SubCategory.defaultSubCategories(for: category.id, categoryType: categoryType)

                    for (subIndex, subCategory) in defaultSubCategories.enumerated() {
                        let cdSubCategory = CDSubCategory(context: context)
                        cdSubCategory.id = subCategory.id
                        cdSubCategory.name = subCategory.name
                        cdSubCategory.categoryId = subCategory.categoryId
                        cdSubCategory.iconName = subCategory.iconName
                        cdSubCategory.colorHex = subCategory.colorHex
                        cdSubCategory.isActive = subCategory.isActive
                        cdSubCategory.sortOrder = Int32(subCategory.sortOrder)
                        cdSubCategory.subCategoryDescription = subCategory.description
                        cdSubCategory.budgetPercentage = subCategory.budgetPercentage
                        cdSubCategory.isDefault = subCategory.isDefault
                        cdSubCategory.createdAt = subCategory.createdAt
                        cdSubCategory.updatedAt = subCategory.updatedAt
                        cdSubCategory.category = cdCategory
                    }
                }
            }

            print("Successfully initialized \(defaultCategories.count) default categories")
        }
    }

    // MARK: - Notification Handling

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSaveNotification(_:)),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }

    @objc private func contextDidSaveNotification(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext else { return }

        // Merge changes into view context if this was a background context save
        if context !== viewContext {
            DispatchQueue.main.async { [weak self] in
                self?.viewContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    // MARK: - Database Management

    /// Deletes all data from the database (useful for testing)
    func deleteAllData() async throws {
        try await performBackgroundTask { context in
            // Delete all entities in dependency order
            let entityNames = ["CDPlanMonthlyBreakdown", "CDFinancialPlan", "CDExpense", "CDSubCategory", "CDCategory"]

            for entityName in entityNames {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                let objectIDs = result?.result as? [NSManagedObjectID] ?? []

                // Merge the changes into the view context
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.viewContext])
            }
        }
    }

    /// Gets database statistics
    func getDatabaseStats() async throws -> DatabaseStats {
        return try await performBackgroundTask { context in
            let categoryCount = try context.count(for: CDCategory.fetchRequest())
            let subCategoryCount = try context.count(for: CDSubCategory.fetchRequest())
            let expenseCount = try context.count(for: CDExpense.fetchRequest())
            let planCount = try context.count(for: CDFinancialPlan.fetchRequest())
            let breakdownCount = try context.count(for: CDPlanMonthlyBreakdown.fetchRequest())

            return DatabaseStats(
                categoryCount: categoryCount,
                subCategoryCount: subCategoryCount,
                expenseCount: expenseCount,
                planCount: planCount,
                breakdownCount: breakdownCount
            )
        }
    }
}

// MARK: - Core Data Error Types

enum CoreDataError: LocalizedError {
    case saveError(Error)
    case fetchError(Error)
    case entityNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchError(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

// MARK: - Database Statistics

struct DatabaseStats {
    let categoryCount: Int
    let subCategoryCount: Int
    let expenseCount: Int
    let planCount: Int
    let breakdownCount: Int

    var totalRecords: Int {
        return categoryCount + subCategoryCount + expenseCount + planCount + breakdownCount
    }
}

// MARK: - Preview Helper

#if DEBUG
extension CoreDataStack {
    /// Creates an in-memory Core Data stack for SwiftUI previews
    static let preview: CoreDataStack = {
        let stack = CoreDataStack()
        let container = NSPersistentContainer(name: "ExpenseTracker")

        // Use in-memory store for previews
        container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Preview Core Data error: \(error)")
            }
        }

        stack.persistentContainer = container
        return stack
    }()
}
#endif