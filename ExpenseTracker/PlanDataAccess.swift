//
//  PlanDataAccess.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import CoreData
import Combine

/// Data access layer for FinancialPlan and PlanMonthlyBreakdown entities
/// Provides comprehensive CRUD operations, analytics, and financial planning business logic
@MainActor
class PlanDataAccess: ObservableObject {

    // MARK: - Properties

    private let coreDataStack: CoreDataStack

    /// Published property for financial plans to notify SwiftUI views
    @Published var financialPlans: [FinancialPlan] = []

    /// Published property for active plans
    @Published var activePlans: [FinancialPlan] = []

    /// Published property for monthly breakdowns
    @Published var monthlyBreakdowns: [PlanMonthlyBreakdown] = []

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadFinancialPlans()
    }

    // MARK: - Financial Plan CRUD Operations

    /// Creates a new financial plan
    /// - Parameter plan: The financial plan to create
    /// - Throws: Core Data error if creation fails
    func createFinancialPlan(_ plan: FinancialPlan) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let cdPlan = CDFinancialPlan.from(plan, context: context)

            // Create monthly breakdowns for the plan
            let monthlyBreakdowns = PlanMonthlyBreakdown.createBreakdownsForPlan(plan)
            for breakdown in monthlyBreakdowns {
                let cdBreakdown = CDPlanMonthlyBreakdown.from(breakdown, context: context)
                cdBreakdown.plan = cdPlan
                cdPlan.addToMonthlyBreakdowns(cdBreakdown)
            }
        }

        await loadFinancialPlans()
    }

    /// Retrieves a financial plan by ID
    /// - Parameter id: The plan ID
    /// - Returns: FinancialPlan if found, nil otherwise
    /// - Throws: Core Data error if fetch fails
    func getFinancialPlan(by id: String) async throws -> FinancialPlan? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            let results = try context.fetch(request)
            return results.first?.toFinancialPlan()
        }
    }

    /// Retrieves all financial plans
    /// - Parameters:
    ///   - includeInactive: Whether to include inactive plans
    ///   - sortBy: Sort field
    ///   - ascending: Sort direction
    /// - Returns: Array of financial plans
    /// - Throws: Core Data error if fetch fails
    func getAllFinancialPlans(
        includeInactive: Bool = false,
        sortBy: PlanSortField = .startDate,
        ascending: Bool = true
    ) async throws -> [FinancialPlan] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()

            if !includeInactive {
                request.predicate = NSPredicate(format: "isActive == YES")
            }

            request.sortDescriptors = [NSSortDescriptor(key: sortBy.coreDataKey, ascending: ascending)]

            let results = try context.fetch(request)
            return results.map { $0.toFinancialPlan() }
        }
    }

    /// Updates an existing financial plan
    /// - Parameter plan: The updated financial plan
    /// - Throws: Core Data error if update fails
    func updateFinancialPlan(_ plan: FinancialPlan) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", plan.id)
            request.fetchLimit = 1

            guard let cdPlan = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            cdPlan.update(from: plan)

            // Update or create monthly breakdowns if date range changed
            let existingBreakdowns = cdPlan.monthlyBreakdowns?.allObjects as? [CDPlanMonthlyBreakdown] ?? []
            let newBreakdowns = PlanMonthlyBreakdown.createBreakdownsForPlan(plan)

            // Remove old breakdowns that are no longer needed
            for existingBreakdown in existingBreakdowns {
                let monthExists = newBreakdowns.contains { $0.month == existingBreakdown.month }
                if !monthExists {
                    context.delete(existingBreakdown)
                }
            }

            // Add or update breakdowns
            for newBreakdown in newBreakdowns {
                if let existingBreakdown = existingBreakdowns.first(where: { $0.month == newBreakdown.month }) {
                    // Update existing breakdown
                    existingBreakdown.update(from: newBreakdown)
                } else {
                    // Create new breakdown
                    let cdBreakdown = CDPlanMonthlyBreakdown.from(newBreakdown, context: context)
                    cdBreakdown.plan = cdPlan
                    cdPlan.addToMonthlyBreakdowns(cdBreakdown)
                }
            }
        }

        await loadFinancialPlans()
    }

    /// Deletes a financial plan and all its monthly breakdowns
    /// - Parameter id: The plan ID to delete
    /// - Throws: Core Data error if deletion fails
    func deleteFinancialPlan(by id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            guard let cdPlan = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            // Monthly breakdowns will be deleted automatically due to cascade delete rule
            context.delete(cdPlan)
        }

        await loadFinancialPlans()
    }

    // MARK: - Monthly Breakdown CRUD Operations

    /// Creates a new monthly breakdown
    /// - Parameter breakdown: The monthly breakdown to create
    /// - Throws: Core Data error if creation fails
    func createMonthlyBreakdown(_ breakdown: PlanMonthlyBreakdown) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let cdBreakdown = CDPlanMonthlyBreakdown.from(breakdown, context: context)

            // Set up relationship with plan
            let planRequest: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            planRequest.predicate = NSPredicate(format: "id == %@", breakdown.planId)
            planRequest.fetchLimit = 1

            if let plan = try context.fetch(planRequest).first {
                cdBreakdown.plan = plan
                plan.addToMonthlyBreakdowns(cdBreakdown)
            }
        }

        await loadMonthlyBreakdowns()
    }

    /// Retrieves a monthly breakdown by ID
    /// - Parameter id: The breakdown ID
    /// - Returns: PlanMonthlyBreakdown if found, nil otherwise
    /// - Throws: Core Data error if fetch fails
    func getMonthlyBreakdown(by id: String) async throws -> PlanMonthlyBreakdown? {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            let results = try context.fetch(request)
            return results.first?.toPlanMonthlyBreakdown()
        }
    }

    /// Retrieves monthly breakdowns for a specific plan
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - year: Optional year filter
    ///   - sortAscending: Sort direction by date
    /// - Returns: Array of monthly breakdowns
    /// - Throws: Core Data error if fetch fails
    func getMonthlyBreakdowns(
        for planId: String,
        year: Int? = nil,
        sortAscending: Bool = true
    ) async throws -> [PlanMonthlyBreakdown] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()

            var predicates = [NSPredicate(format: "planId == %@", planId)]
            if let year = year {
                predicates.append(NSPredicate(format: "year == %d", year))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "year", ascending: sortAscending),
                NSSortDescriptor(key: "monthNumber", ascending: sortAscending)
            ]

            let results = try context.fetch(request)
            return results.map { $0.toPlanMonthlyBreakdown() }
        }
    }

    /// Updates an existing monthly breakdown
    /// - Parameter breakdown: The updated monthly breakdown
    /// - Throws: Core Data error if update fails
    func updateMonthlyBreakdown(_ breakdown: PlanMonthlyBreakdown) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", breakdown.id)
            request.fetchLimit = 1

            guard let cdBreakdown = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            cdBreakdown.update(from: breakdown)
        }

        await loadMonthlyBreakdowns()
    }

    /// Deletes a monthly breakdown
    /// - Parameter id: The breakdown ID to delete
    /// - Throws: Core Data error if deletion fails
    func deleteMonthlyBreakdown(by id: String) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1

            guard let cdBreakdown = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            context.delete(cdBreakdown)
        }

        await loadMonthlyBreakdowns()
    }

    // MARK: - Analytics and Reporting

    /// Gets financial plan performance summary
    /// - Parameter planId: The plan ID
    /// - Returns: Dictionary with performance metrics
    /// - Throws: Core Data error if calculation fails
    func getPlanPerformanceSummary(for planId: String) async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let breakdownRequest: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            breakdownRequest.predicate = NSPredicate(format: "planId == %@ AND isCompleted == YES", planId)

            let completedBreakdowns = try context.fetch(breakdownRequest)
            let breakdowns = completedBreakdowns.map { $0.toPlanMonthlyBreakdown() }

            guard !breakdowns.isEmpty else {
                return [
                    "totalPlannedIncome": 0.0,
                    "totalActualIncome": 0.0,
                    "totalPlannedExpenses": 0.0,
                    "totalActualExpenses": 0.0,
                    "totalPlannedSavings": 0.0,
                    "totalActualSavings": 0.0,
                    "averageFinancialHealthScore": 0.0,
                    "incomeVariance": 0.0,
                    "expenseVariance": 0.0,
                    "savingsVariance": 0.0,
                    "completedMonths": 0
                ]
            }

            let totalPlannedIncome = breakdowns.reduce(0) { $0 + $1.plannedIncome }
            let totalActualIncome = breakdowns.reduce(0) { $0 + $1.actualIncome }
            let totalPlannedExpenses = breakdowns.reduce(0) { $0 + $1.plannedExpenses }
            let totalActualExpenses = breakdowns.reduce(0) { $0 + $1.actualExpenses }
            let totalPlannedSavings = breakdowns.reduce(0) { $0 + $1.plannedSavings }
            let totalActualSavings = breakdowns.reduce(0) { $0 + $1.actualSavings }

            let averageHealthScore = breakdowns.reduce(0) { $0 + $1.financialHealthScore } / Double(breakdowns.count)

            return [
                "totalPlannedIncome": totalPlannedIncome,
                "totalActualIncome": totalActualIncome,
                "totalPlannedExpenses": totalPlannedExpenses,
                "totalActualExpenses": totalActualExpenses,
                "totalPlannedSavings": totalPlannedSavings,
                "totalActualSavings": totalActualSavings,
                "averageFinancialHealthScore": averageHealthScore,
                "incomeVariance": totalActualIncome - totalPlannedIncome,
                "expenseVariance": totalPlannedExpenses - totalActualExpenses,
                "savingsVariance": totalActualSavings - totalPlannedSavings,
                "completedMonths": breakdowns.count
            ]
        }
    }

    /// Gets monthly trends for a plan
    /// - Parameter planId: The plan ID
    /// - Returns: Dictionary with trend data
    /// - Throws: Core Data error if calculation fails
    func getMonthlyTrends(for planId: String) async throws -> [String: Any] {
        let breakdowns = try await getMonthlyBreakdowns(for: planId, sortAscending: true)

        let incomeData = breakdowns.map { ["month": $0.month, "actual": $0.actualIncome, "planned": $0.plannedIncome] }
        let expenseData = breakdowns.map { ["month": $0.month, "actual": $0.actualExpenses, "planned": $0.plannedExpenses] }
        let savingsData = breakdowns.map { ["month": $0.month, "actual": $0.actualSavings, "planned": $0.plannedSavings] }
        let healthScoreData = breakdowns.map { ["month": $0.month, "score": $0.financialHealthScore] }

        return [
            "incomeData": incomeData,
            "expenseData": expenseData,
            "savingsData": savingsData,
            "healthScoreData": healthScoreData
        ]
    }

    /// Gets budget vs actual comparison for a specific month
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - month: The month string (YYYY-MM)
    /// - Returns: Dictionary with comparison data
    /// - Throws: Core Data error if calculation fails
    func getBudgetVsActualComparison(for planId: String, month: String) async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            request.predicate = NSPredicate(format: "planId == %@ AND month == %@", planId, month)
            request.fetchLimit = 1

            guard let cdBreakdown = try context.fetch(request).first else {
                throw CoreDataError.entityNotFound
            }

            let breakdown = cdBreakdown.toPlanMonthlyBreakdown()

            return [
                "month": breakdown.month,
                "income": [
                    "planned": breakdown.plannedIncome,
                    "actual": breakdown.actualIncome,
                    "variance": breakdown.incomeVariance,
                    "achievement": breakdown.incomeAchievementPercentage
                ],
                "expenses": [
                    "planned": breakdown.plannedExpenses,
                    "actual": breakdown.actualExpenses,
                    "variance": breakdown.expenseVariance,
                    "control": breakdown.expenseControlPercentage
                ],
                "savings": [
                    "planned": breakdown.plannedSavings,
                    "actual": breakdown.actualSavings,
                    "variance": breakdown.savingsVariance,
                    "achievement": breakdown.savingsAchievementPercentage
                ],
                "healthScore": breakdown.financialHealthScore
            ]
        }
    }

    /// Gets category-wise performance for a plan
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - startMonth: Start month (optional)
    ///   - endMonth: End month (optional)
    /// - Returns: Dictionary with category performance data
    /// - Throws: Core Data error if calculation fails
    func getCategoryPerformance(for planId: String, startMonth: String? = nil, endMonth: String? = nil) async throws -> [String: Any] {
        return try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()

            var predicates = [NSPredicate(format: "planId == %@", planId)]
            if let startMonth = startMonth {
                predicates.append(NSPredicate(format: "month >= %@", startMonth))
            }
            if let endMonth = endMonth {
                predicates.append(NSPredicate(format: "month <= %@", endMonth))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            let cdBreakdowns = try context.fetch(request)
            let breakdowns = cdBreakdowns.map { $0.toPlanMonthlyBreakdown() }

            var categoryPerformance: [String: [String: Double]] = [:]

            for breakdown in breakdowns {
                for (categoryId, categoryData) in breakdown.categoryBreakdown {
                    if categoryPerformance[categoryId] == nil {
                        categoryPerformance[categoryId] = [
                            "totalPlanned": 0.0,
                            "totalActual": 0.0,
                            "totalVariance": 0.0,
                            "transactionCount": 0.0
                        ]
                    }

                    categoryPerformance[categoryId]?["totalPlanned"]! += categoryData.plannedBudget
                    categoryPerformance[categoryId]?["totalActual"]! += categoryData.actualExpenses
                    categoryPerformance[categoryId]?["totalVariance"]! += categoryData.expenseVariance
                    categoryPerformance[categoryId]?["transactionCount"]! += Double(categoryData.transactionCount)
                }
            }

            return [
                "categoryPerformance": categoryPerformance,
                "monthsAnalyzed": breakdowns.count
            ]
        }
    }

    // MARK: - Plan Management

    /// Gets currently active plans (within their date range)
    /// - Returns: Array of currently active plans
    /// - Throws: Core Data error if fetch fails
    func getCurrentlyActivePlans() async throws -> [FinancialPlan] {
        return try await coreDataStack.performBackgroundTask { context in
            let now = Date()
            let request: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            request.predicate = NSPredicate(format: "isActive == YES AND startDate <= %@ AND endDate >= %@", now as NSDate, now as NSDate)
            request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]

            let results = try context.fetch(request)
            return results.map { $0.toFinancialPlan() }
        }
    }

    /// Activates a plan and optionally deactivates others
    /// - Parameters:
    ///   - planId: The plan ID to activate
    ///   - deactivateOthers: Whether to deactivate other plans
    /// - Throws: Core Data error if update fails
    func activatePlan(_ planId: String, deactivateOthers: Bool = false) async throws {
        try await coreDataStack.performBackgroundTask { context in
            if deactivateOthers {
                // Deactivate all other plans
                let allPlansRequest: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
                allPlansRequest.predicate = NSPredicate(format: "id != %@", planId)

                let otherPlans = try context.fetch(allPlansRequest)
                for plan in otherPlans {
                    plan.isActive = false
                    plan.updatedAt = Date()
                }
            }

            // Activate the target plan
            let targetPlanRequest: NSFetchRequest<CDFinancialPlan> = CDFinancialPlan.fetchRequest()
            targetPlanRequest.predicate = NSPredicate(format: "id == %@", planId)
            targetPlanRequest.fetchLimit = 1

            if let targetPlan = try context.fetch(targetPlanRequest).first {
                targetPlan.isActive = true
                targetPlan.updatedAt = Date()
            }
        }

        await loadFinancialPlans()
    }

    /// Updates monthly breakdown from actual expense data
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - month: The month string
    ///   - expenseData: Dictionary with expense data by category/subcategory
    /// - Throws: Core Data error if update fails
    func updateBreakdownFromExpenses(planId: String, month: String, expenseData: [String: Any]) async throws {
        try await coreDataStack.performBackgroundTask { context in
            let request: NSFetchRequest<CDPlanMonthlyBreakdown> = CDPlanMonthlyBreakdown.fetchRequest()
            request.predicate = NSPredicate(format: "planId == %@ AND month == %@", planId, month)
            request.fetchLimit = 1

            guard let cdBreakdown = try context.fetch(request).first else {
                return // No breakdown exists for this month
            }

            let breakdown = cdBreakdown.toPlanMonthlyBreakdown()

            // Update actual expenses from the expense data
            let totalExpenses = expenseData["totalAmount"] as? Double ?? 0.0
            let categoryBreakdownData = expenseData["categoryBreakdown"] as? [String: [String: Any]] ?? [:]

            var updatedCategoryBreakdown = breakdown.categoryBreakdown

            for (categoryId, categoryData) in categoryBreakdownData {
                let actualExpenses = categoryData["totalAmount"] as? Double ?? 0.0
                let transactionCount = categoryData["transactionCount"] as? Int ?? 0

                if var existingCategoryData = updatedCategoryBreakdown[categoryId] {
                    existingCategoryData.actualExpenses = actualExpenses
                    existingCategoryData.transactionCount = transactionCount
                    if transactionCount > 0 {
                        existingCategoryData.averageTransactionAmount = actualExpenses / Double(transactionCount)
                    }
                    updatedCategoryBreakdown[categoryId] = existingCategoryData
                }
            }

            let updatedBreakdown = breakdown.updated(with: [
                "actualExpenses": totalExpenses,
                "actualSavings": max(breakdown.actualIncome - totalExpenses, 0),
                "categoryBreakdown": updatedCategoryBreakdown
            ])

            cdBreakdown.update(from: updatedBreakdown)
        }

        await loadMonthlyBreakdowns()
    }

    // MARK: - Data Loading

    /// Loads financial plans from Core Data into published properties
    private func loadFinancialPlans() {
        Task {
            do {
                let allPlans = try await getAllFinancialPlans(includeInactive: true)
                let currentlyActive = try await getCurrentlyActivePlans()

                await MainActor.run {
                    self.financialPlans = allPlans
                    self.activePlans = currentlyActive
                }
            } catch {
                print("Failed to load financial plans: \(error)")
            }
        }
    }

    /// Loads monthly breakdowns from Core Data
    private func loadMonthlyBreakdowns() {
        Task {
            do {
                // Load breakdowns for all active plans
                var allBreakdowns: [PlanMonthlyBreakdown] = []

                for plan in activePlans {
                    let planBreakdowns = try await getMonthlyBreakdowns(for: plan.id)
                    allBreakdowns.append(contentsOf: planBreakdowns)
                }

                await MainActor.run {
                    self.monthlyBreakdowns = allBreakdowns
                }
            } catch {
                print("Failed to load monthly breakdowns: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

enum PlanSortField: String, CaseIterable {
    case name = "name"
    case startDate = "startDate"
    case endDate = "endDate"
    case createdAt = "createdAt"
    case totalIncome = "totalIncome"
    case savingsGoal = "savingsGoal"

    var coreDataKey: String {
        return rawValue
    }

    var displayName: String {
        switch self {
        case .name: return L("sort_by_name")
        case .startDate: return L("sort_by_start_date")
        case .endDate: return L("sort_by_end_date")
        case .createdAt: return L("sort_by_created")
        case .totalIncome: return L("sort_by_income")
        case .savingsGoal: return L("sort_by_savings_goal")
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension PlanDataAccess {
    static let preview: PlanDataAccess = {
        return PlanDataAccess(coreDataStack: CoreDataStack.preview)
    }()
}
#endif