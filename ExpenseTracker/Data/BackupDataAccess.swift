//
//  BackupDataAccess.swift
//  ExpenseTracker
//
//  Bulk reads and writes for backup / restore.
//
//  This deliberately bypasses the per-entity data access classes. Each of those saves
//  the context on every call, which would leave the database half-restored if an
//  import failed partway. Everything here runs against one context and commits with a
//  single save, mirroring Room's `withTransaction` on the Android side.
//

import Foundation
import CoreData

class BackupDataAccess {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    // MARK: - Bulk Reads

    func fetchEverything() async throws -> (
        categories: [Category],
        subCategories: [SubCategory],
        expenses: [Expense],
        plans: [FinancialPlan],
        breakdowns: [PlanMonthlyBreakdown]
    ) {
        return try await context.perform {
            let categoryRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            let subCategoryRequest: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
            let expenseRequest: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
            let planRequest: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
            let breakdownRequest: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()

            let categories = try self.context.fetch(categoryRequest).map { Category(from: $0) }
            let subCategories = try self.context.fetch(subCategoryRequest).map { SubCategory(from: $0) }
            let expenses = try self.context.fetch(expenseRequest).map { Expense(from: $0) }
            let plans = try self.context.fetch(planRequest).map { FinancialPlan(from: $0) }
            let breakdowns = try self.context.fetch(breakdownRequest).map { PlanMonthlyBreakdown(from: $0) }

            return (categories, subCategories, expenses, plans, breakdowns)
        }
    }

    // MARK: - Transactional Restore

    /// Replaces or merges the stored data in a single transaction.
    ///
    /// Deletes go through the context rather than `NSBatchDeleteRequest` on purpose:
    /// a batch delete writes straight to the store and cannot be rolled back, which
    /// would defeat the all-or-nothing guarantee this method exists to provide.
    func restore(
        categories: [Category],
        subCategories: [SubCategory],
        expenses: [Expense],
        plans: [FinancialPlan],
        breakdowns: [PlanMonthlyBreakdown],
        strategy: ImportStrategy
    ) async throws {
        try await context.perform {
            do {
                if strategy == .replaceAll {
                    try self.deleteAllInCurrentTransaction()
                } else {
                    // Merge: drop only the rows the incoming file will re-supply, so
                    // re-importing the same backup updates rather than duplicates.
                    let breakdownRequest: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
                    let planRequest: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
                    let expenseRequest: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
                    let subCategoryRequest: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
                    let categoryRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()

                    try self.deleteMatching(breakdownRequest, ids: breakdowns.map(\.id))
                    try self.deleteMatching(planRequest, ids: plans.map(\.id))
                    try self.deleteMatching(expenseRequest, ids: expenses.map(\.id))
                    try self.deleteMatching(subCategoryRequest, ids: subCategories.map(\.id))
                    try self.deleteMatching(categoryRequest, ids: categories.map(\.id))
                }

                // Insert parents before children so any relationship the model defines
                // has its target present.
                categories.forEach { _ = $0.toCoreData(context: self.context) }
                subCategories.forEach { _ = $0.toCoreData(context: self.context) }
                expenses.forEach { _ = $0.toCoreData(context: self.context) }
                plans.forEach { _ = $0.toCoreData(context: self.context) }
                breakdowns.forEach { _ = $0.toCoreData(context: self.context) }

                try self.context.save()
            } catch {
                // Discard every pending insert and delete, leaving the store as it was.
                self.context.rollback()
                throw error
            }
        }
    }

    // MARK: - Deletion Helpers

    /// Children first — an expense referencing a deleted category would otherwise be
    /// orphaned mid-transaction.
    private func deleteAllInCurrentTransaction() throws {
        let breakdownRequest: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
        let planRequest: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        let expenseRequest: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        let subCategoryRequest: NSFetchRequest<SubCategoryEntity> = SubCategoryEntity.fetchRequest()
        let categoryRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()

        try deleteAll(breakdownRequest)
        try deleteAll(planRequest)
        try deleteAll(expenseRequest)
        try deleteAll(subCategoryRequest)
        try deleteAll(categoryRequest)
    }

    private func deleteAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws {
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
    }

    private func deleteMatching<T: NSManagedObject>(_ request: NSFetchRequest<T>, ids: [String]) throws {
        guard !ids.isEmpty else { return }

        request.predicate = NSPredicate(format: "id IN %@", ids)
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
    }
}
