//
//  PlanDataAccess.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanDao.kt
//

import Foundation
import CoreData

class PlanDataAccess {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }

    // MARK: - Financial Plans

    func getAllPlans() async throws -> [FinancialPlan] {
        let request: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { FinancialPlan(from: $0) }
    }

    func getPlan(planId: String) async throws -> FinancialPlan? {
        let request: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", planId)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first.map { FinancialPlan(from: $0) }
    }

    func insertPlan(_ plan: FinancialPlan) async throws {
        let entity = plan.toCoreData(context: context)
        try context.save()
    }

    func updatePlan(_ plan: FinancialPlan) async throws {
        let request: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", plan.id)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.name = plan.name
            entity.startDate = plan.startDate
            entity.durationInMonths = Int32(plan.durationInMonths)
            entity.monthlyIncome = plan.monthlyIncome
            entity.manualMonthlyExpenses = plan.manualMonthlyExpenses
            entity.useAppExpenseData = plan.useAppExpenseData
            entity.isInflationApplied = plan.isInflationApplied
            entity.inflationRate = plan.inflationRate
            entity.isInterestApplied = plan.isInterestApplied
            entity.interestRate = plan.interestRate
            entity.interestType = plan.interestType.rawValue
            entity.createdAt = plan.createdAt
            entity.updatedAt = plan.updatedAt
            entity.defaultCurrency = plan.defaultCurrency
            try context.save()
        }
    }

    func deletePlan(_ plan: FinancialPlan) async throws {
        let request: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", plan.id)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deletePlanById(_ planId: String) async throws {
        let request: NSFetchRequest<FinancialPlanEntity> = FinancialPlanEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", planId)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    // MARK: - Plan Monthly Breakdowns

    func getPlanBreakdowns(planId: String) async throws -> [PlanMonthlyBreakdown] {
        let request: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
        request.predicate = NSPredicate(format: "planId == %@", planId)
        request.sortDescriptors = [NSSortDescriptor(key: "monthIndex", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { PlanMonthlyBreakdown(from: $0) }
    }

    func insertBreakdown(_ breakdown: PlanMonthlyBreakdown) async throws {
        let entity = breakdown.toCoreData(context: context)
        try context.save()
    }

    func insertBreakdowns(_ breakdowns: [PlanMonthlyBreakdown]) async throws {
        for breakdown in breakdowns {
            _ = breakdown.toCoreData(context: context)
        }
        try context.save()
    }

    func updateBreakdown(_ breakdown: PlanMonthlyBreakdown) async throws {
        let request: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", breakdown.id)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.planId = breakdown.planId
            entity.monthIndex = Int32(breakdown.monthIndex)
            entity.projectedIncome = breakdown.projectedIncome
            entity.fixedExpenses = breakdown.fixedExpenses
            entity.averageExpenses = breakdown.averageExpenses
            entity.totalProjectedExpenses = breakdown.totalProjectedExpenses
            entity.netAmount = breakdown.netAmount
            entity.interestEarned = breakdown.interestEarned
            entity.cumulativeNet = breakdown.cumulativeNet
            try context.save()
        }
    }

    func deleteBreakdown(_ breakdown: PlanMonthlyBreakdown) async throws {
        let request: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", breakdown.id)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteBreakdownsForPlan(planId: String) async throws {
        let request: NSFetchRequest<PlanMonthlyBreakdownEntity> = PlanMonthlyBreakdownEntity.fetchRequest()
        request.predicate = NSPredicate(format: "planId == %@", planId)

        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    // MARK: - Combined Operations

    func getPlanWithBreakdowns(planId: String) async throws -> PlanWithBreakdowns? {
        guard let plan = try await getPlan(planId: planId) else { return nil }
        let breakdowns = try await getPlanBreakdowns(planId: planId)
        return PlanWithBreakdowns(plan: plan, breakdowns: breakdowns)
    }

    func getAllPlansWithBreakdowns() async throws -> [PlanWithBreakdowns] {
        let plans = try await getAllPlans()
        var results: [PlanWithBreakdowns] = []

        for plan in plans {
            let breakdowns = try await getPlanBreakdowns(planId: plan.id)
            results.append(PlanWithBreakdowns(plan: plan, breakdowns: breakdowns))
        }

        return results
    }
}

// MARK: - Relation Data Structure
struct PlanWithBreakdowns {
    let plan: FinancialPlan
    let breakdowns: [PlanMonthlyBreakdown]
}