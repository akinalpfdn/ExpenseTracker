//
//  PlanRepository.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanRepository.kt
//

import Foundation

class PlanRepository {
    private let planDataAccess: PlanDataAccess
    private let expenseRepository: ExpenseRepository

    init(planDataAccess: PlanDataAccess = PlanDataAccess(), expenseRepository: ExpenseRepository = ExpenseRepository()) {
        self.planDataAccess = planDataAccess
        self.expenseRepository = expenseRepository
    }

    // MARK: - Plan Operations

    func getAllPlans() async throws -> [FinancialPlan] {
        return try await planDataAccess.getAllPlans()
    }

    func getAllPlansWithBreakdowns() async throws -> [PlanWithBreakdowns] {
        return try await planDataAccess.getAllPlansWithBreakdowns()
    }

    func getPlan(planId: String) async throws -> FinancialPlan? {
        return try await planDataAccess.getPlan(planId: planId)
    }

    func getPlanWithBreakdowns(planId: String) async throws -> PlanWithBreakdowns? {
        return try await planDataAccess.getPlanWithBreakdowns(planId: planId)
    }

    func insertPlan(_ plan: FinancialPlan) async throws {
        try await planDataAccess.insertPlan(plan)
        try await generatePlanBreakdowns(planId: plan.id)
    }

    func updatePlan(_ plan: FinancialPlan) async throws {
        let updatedPlan = FinancialPlan(
            id: plan.id,
            name: plan.name,
            startDate: plan.startDate,
            durationInMonths: plan.durationInMonths,
            monthlyIncome: plan.monthlyIncome,
            manualMonthlyExpenses: plan.manualMonthlyExpenses,
            useAppExpenseData: plan.useAppExpenseData,
            isInflationApplied: plan.isInflationApplied,
            inflationRate: plan.inflationRate,
            isInterestApplied: plan.isInterestApplied,
            interestRate: plan.interestRate,
            interestType: plan.interestType,
            createdAt: plan.createdAt,
            updatedAt: Date(),
            defaultCurrency: plan.defaultCurrency
        )
        try await planDataAccess.updatePlan(updatedPlan)
        try await regeneratePlanBreakdowns(planId: plan.id)
    }

    func deletePlan(planId: String) async throws {
        try await planDataAccess.deletePlanById(planId)
    }

    func regeneratePlanBreakdowns(planId: String) async throws {
        try await planDataAccess.deleteBreakdownsForPlan(planId: planId)
        try await generatePlanBreakdowns(planId: planId)
    }

    func updateBreakdown(_ updatedBreakdown: PlanMonthlyBreakdown) async throws {
        try await planDataAccess.updateBreakdown(updatedBreakdown)
    }

    func recalculateCumulativeAmounts(planId: String) async throws {
        let breakdowns = try await planDataAccess.getPlanBreakdowns(planId: planId).sorted { $0.monthIndex < $1.monthIndex }

        var cumulativeNet = 0.0
        let updatedBreakdowns = breakdowns.map { breakdown in
            cumulativeNet += breakdown.netAmount
            return PlanMonthlyBreakdown(
                id: breakdown.id,
                planId: breakdown.planId,
                monthIndex: breakdown.monthIndex,
                projectedIncome: breakdown.projectedIncome,
                fixedExpenses: breakdown.fixedExpenses,
                averageExpenses: breakdown.averageExpenses,
                totalProjectedExpenses: breakdown.totalProjectedExpenses,
                netAmount: breakdown.netAmount,
                interestEarned: breakdown.interestEarned,
                cumulativeNet: cumulativeNet
            )
        }

        for breakdown in updatedBreakdowns {
            try await planDataAccess.updateBreakdown(breakdown)
        }
    }

    // MARK: - Private Methods

    private func generatePlanBreakdowns(planId: String) async throws {
        guard let plan = try await planDataAccess.getPlan(planId: planId) else { return }

        var breakdowns: [PlanMonthlyBreakdown] = []
        var cumulativeNet = 0.0

        let allExpenses = try await expenseRepository.getAllExpensesDirect()

        for monthIndex in 0..<plan.durationInMonths {
            let projectedIncome = plan.getMonthlyIncomeAtMonth(monthIndex: monthIndex)

            let baseExpenses: Double
            if plan.useAppExpenseData {
                let monthDate = Calendar.current.date(byAdding: .month, value: monthIndex, to: plan.startDate) ?? plan.startDate

                let recurringExpenses = getRecurringExpensesForMonth(
                    allExpenses: allExpenses,
                    monthDate: monthDate,
                    defaultCurrency: plan.defaultCurrency
                )

                let averageOneTimeExpenses = try await getAverageOneTimeExpenses()

                baseExpenses = recurringExpenses + averageOneTimeExpenses
            } else {
                baseExpenses = plan.manualMonthlyExpenses
            }

            let adjustedExpenses: Double
            if plan.isInflationApplied && plan.inflationRate > 0 {
                let monthlyInflationRate = plan.inflationRate / 12 / 100
                adjustedExpenses = baseExpenses * pow(1 + monthlyInflationRate, Double(monthIndex))
            } else {
                adjustedExpenses = baseExpenses
            }

            let netAmount = projectedIncome - adjustedExpenses

            let interestEarned: Double
            if plan.isInterestApplied && cumulativeNet > 0 && plan.interestRate > 0 {
                switch plan.interestType {
                case .simple:
                    let annualRate = plan.interestRate / 100
                    let monthlySimpleRate = annualRate / 12
                    interestEarned = cumulativeNet * monthlySimpleRate
                case .compound:
                    let annualRate = plan.interestRate / 100
                    let monthlyCompoundRate = pow(1 + annualRate, 1.0 / 12.0) - 1
                    interestEarned = cumulativeNet * monthlyCompoundRate
                }
            } else {
                interestEarned = 0.0
            }

            cumulativeNet += netAmount + interestEarned

            let breakdown = PlanMonthlyBreakdown(
                planId: planId,
                monthIndex: monthIndex,
                projectedIncome: projectedIncome,
                fixedExpenses: plan.manualMonthlyExpenses > 0 ? 0.0 : adjustedExpenses,
                averageExpenses: plan.manualMonthlyExpenses > 0 ? adjustedExpenses : 0.0,
                totalProjectedExpenses: adjustedExpenses,
                netAmount: netAmount,
                interestEarned: interestEarned,
                cumulativeNet: cumulativeNet
            )

            breakdowns.append(breakdown)
        }

        try await planDataAccess.insertBreakdowns(breakdowns)
    }

    private func getRecurringExpensesForMonth(
        allExpenses: [Expense],
        monthDate: Date,
        defaultCurrency: String
    ) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: monthDate)
        guard let year = components.year, let month = components.month else { return 0.0 }

        let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? monthDate
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? monthDate

        return allExpenses.filter { expense in
            expense.recurrenceType != .NONE &&
            expense.date <= endOfMonth &&
            expense.date >= calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        }.reduce(0.0) { total, expense in
            total + expense.getAmountInDefaultCurrency(defaultCurrency: defaultCurrency)
        }
    }

    private func getAverageOneTimeExpenses() async throws -> Double {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate

        let allExpenses = try await expenseRepository.getAllExpensesDirect()
        let oneTimeExpenses = allExpenses.filter { expense in
            expense.date > startDate &&
            expense.date < endDate &&
            expense.recurrenceType == .NONE
        }

        let totalSpent = oneTimeExpenses.reduce(0.0) { $0 + $1.amount }
        return totalSpent / 3
    }

    // MARK: - Current Position

    func getCurrentFinancialPosition(planId: String) async throws -> PlanCurrentPosition? {
        guard let planWithBreakdowns = try await getPlanWithBreakdowns(planId: planId) else { return nil }
        let plan = planWithBreakdowns.plan

        if !plan.isActive() { return nil }

        let monthsElapsed = plan.getMonthsElapsed()
        let currentBreakdown = planWithBreakdowns.breakdowns.first { $0.monthIndex == monthsElapsed - 1 }

        let expectedCumulativeNet = currentBreakdown?.cumulativeNet ?? 0.0

        let actualExpenses = try await getActualExpensesForPlan(plan: plan, monthsElapsed: monthsElapsed)
        let actualIncome = plan.monthlyIncome * Double(monthsElapsed)
        let actualNet = actualIncome - actualExpenses

        return PlanCurrentPosition(
            planId: planId,
            monthsElapsed: monthsElapsed,
            expectedCumulativeNet: expectedCumulativeNet,
            actualCumulativeNet: actualNet,
            variance: actualNet - expectedCumulativeNet,
            isOnTrack: actualNet >= expectedCumulativeNet * 0.9
        )
    }

    private func getActualExpensesForPlan(plan: FinancialPlan, monthsElapsed: Int) async throws -> Double {
        let planStartDate = plan.startDate
        let endDate = Calendar.current.date(byAdding: .month, value: monthsElapsed, to: planStartDate) ?? planStartDate

        let allExpenses = try await expenseRepository.getAllExpensesDirect()
        return allExpenses.filter { expense in
            expense.date > planStartDate && expense.date < endDate
        }.reduce(0.0) { $0 + $1.amount }
    }

    func updateExpenseData(planId: String) async throws {
        guard let plan = try await planDataAccess.getPlan(planId: planId) else { return }

        if !plan.useAppExpenseData { return }

        let currentMonthIndex = plan.getMonthsElapsed()
        let existingBreakdowns = try await planDataAccess.getPlanBreakdowns(planId: planId)

        let allExpenses = try await expenseRepository.getAllExpensesDirect()

        var updatedBreakdowns: [PlanMonthlyBreakdown] = []
        var cumulativeNet = 0.0

        for monthIndex in 0..<plan.durationInMonths {
            let existingBreakdown = existingBreakdowns.first { $0.monthIndex == monthIndex }

            if monthIndex < currentMonthIndex, let existing = existingBreakdown {
                updatedBreakdowns.append(existing)
                cumulativeNet = existing.cumulativeNet
            } else {
                let projectedIncome = plan.getMonthlyIncomeAtMonth(monthIndex: monthIndex)

                let monthDate = Calendar.current.date(byAdding: .month, value: monthIndex, to: plan.startDate) ?? plan.startDate

                let recurringExpenses = getRecurringExpensesForMonth(
                    allExpenses: allExpenses,
                    monthDate: monthDate,
                    defaultCurrency: plan.defaultCurrency
                )

                let averageOneTimeExpenses = try await getAverageOneTimeExpenses()
                let baseExpenses = recurringExpenses + averageOneTimeExpenses

                let adjustedExpenses: Double
                if plan.isInflationApplied && plan.inflationRate > 0 {
                    let monthlyInflationRate = plan.inflationRate / 12 / 100
                    adjustedExpenses = baseExpenses * pow(1 + monthlyInflationRate, Double(monthIndex))
                } else {
                    adjustedExpenses = baseExpenses
                }

                let netAmount = projectedIncome - adjustedExpenses

                let interestEarned: Double
                if plan.isInterestApplied && cumulativeNet > 0 && plan.interestRate > 0 {
                    switch plan.interestType {
                    case .simple:
                        let annualRate = plan.interestRate / 100
                        let monthlySimpleRate = annualRate / 12
                        interestEarned = cumulativeNet * monthlySimpleRate
                    case .compound:
                        let annualRate = plan.interestRate / 100
                        let monthlyCompoundRate = pow(1 + annualRate, 1.0 / 12.0) - 1
                        interestEarned = cumulativeNet * monthlyCompoundRate
                    }
                } else {
                    interestEarned = 0.0
                }

                cumulativeNet += netAmount + interestEarned

                let updatedBreakdown = PlanMonthlyBreakdown(
                    id: existingBreakdown?.id ?? UUID().uuidString,
                    planId: planId,
                    monthIndex: monthIndex,
                    projectedIncome: projectedIncome,
                    fixedExpenses: 0.0,
                    averageExpenses: adjustedExpenses,
                    totalProjectedExpenses: adjustedExpenses,
                    netAmount: netAmount,
                    interestEarned: interestEarned,
                    cumulativeNet: cumulativeNet
                )

                updatedBreakdowns.append(updatedBreakdown)
            }
        }

        try await planDataAccess.deleteBreakdownsForPlan(planId: planId)
        try await planDataAccess.insertBreakdowns(updatedBreakdowns)

        let updatedPlan = FinancialPlan(
            id: plan.id,
            name: plan.name,
            startDate: plan.startDate,
            durationInMonths: plan.durationInMonths,
            monthlyIncome: plan.monthlyIncome,
            manualMonthlyExpenses: plan.manualMonthlyExpenses,
            useAppExpenseData: plan.useAppExpenseData,
            isInflationApplied: plan.isInflationApplied,
            inflationRate: plan.inflationRate,
            isInterestApplied: plan.isInterestApplied,
            interestRate: plan.interestRate,
            interestType: plan.interestType,
            createdAt: plan.createdAt,
            updatedAt: Date(),
            defaultCurrency: plan.defaultCurrency
        )
        try await planDataAccess.updatePlan(updatedPlan)
    }
}

// MARK: - Data Structures

struct PlanCurrentPosition {
    let planId: String
    let monthsElapsed: Int
    let expectedCumulativeNet: Double
    let actualCumulativeNet: Double
    let variance: Double
    let isOnTrack: Bool
}