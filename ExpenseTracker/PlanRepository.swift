//
//  PlanRepository.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive financial plan repository with complex business logic
/// Provides high-level plan operations, breakdown generation, and financial calculations
/// Uses PlanDataAccess for Core Data operations and adds sophisticated business logic layer
@MainActor
class PlanRepository: ObservableObject {

    // MARK: - Properties

    private let planDataAccess: PlanDataAccess
    private let expenseRepository: ExpenseRepository
    private let categoryRepository: CategoryRepository
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    /// Published property for financial plans
    @Published var financialPlans: [FinancialPlan] = []

    /// Published property for active plans
    @Published var activePlans: [FinancialPlan] = []

    /// Published property for current month's breakdown
    @Published var currentMonthBreakdown: PlanMonthlyBreakdown?

    /// Published property for plan performance summary
    @Published var planPerformanceSummary: PlanPerformanceSummary?

    /// Published property for plan recommendations
    @Published var planRecommendations: [PlanRecommendation] = []

    /// Published property for financial health score
    @Published var financialHealthScore: Double = 0.0

    // MARK: - Initialization

    init(
        planDataAccess: PlanDataAccess = PlanDataAccess(),
        expenseRepository: ExpenseRepository,
        categoryRepository: CategoryRepository,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.planDataAccess = planDataAccess
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.settingsManager = settingsManager
        setupBindings()
        loadInitialData()
    }

    // MARK: - Private Setup Methods

    private func setupBindings() {
        // Listen for data changes from the data access layer
        planDataAccess.$financialPlans
            .sink { [weak self] plans in
                self?.financialPlans = plans
                self?.updateDerivedData()
            }
            .store(in: &cancellables)

        planDataAccess.$activePlans
            .sink { [weak self] plans in
                self?.activePlans = plans
                self?.updateCurrentMonthBreakdown()
            }
            .store(in: &cancellables)

        // Listen for expense changes that might affect plan calculations
        expenseRepository.$thisMonthExpenses
            .sink { [weak self] _ in
                self?.updateCurrentMonthBreakdown()
                self?.refreshPerformanceSummary()
            }
            .store(in: &cancellables)

        // Listen for settings changes that might affect plan calculations
        settingsManager.$currency
            .sink { [weak self] _ in
                self?.refreshPerformanceSummary()
            }
            .store(in: &cancellables)
    }

    private func loadInitialData() {
        Task {
            await refreshAllData()
        }
    }

    // MARK: - Public Methods - Plan CRUD Operations

    /// Creates a new financial plan with comprehensive validation and setup
    /// - Parameter plan: The financial plan to create
    /// - Throws: PlanRepositoryError if validation fails or creation fails
    func createFinancialPlan(_ plan: FinancialPlan) async throws {
        // Validate plan
        try validateFinancialPlan(plan)

        // Check for overlapping plans if exclusive
        if plan.isActive {
            try await checkForOverlappingPlans(plan)
        }

        // Enhance plan with current settings
        let enhancedPlan = enhancePlanWithSettings(plan)

        // Create the plan with automatic breakdown generation
        try await planDataAccess.createFinancialPlan(enhancedPlan)

        // Generate recommendations for the new plan
        await generatePlanRecommendations(for: enhancedPlan)

        // Update financial health score
        await refreshFinancialHealthScore()

        // Refresh performance data
        await refreshPerformanceSummary()

        settingsManager.triggerHapticFeedback(.light)
    }

    /// Updates an existing financial plan
    /// - Parameter plan: The updated financial plan
    /// - Throws: PlanRepositoryError if validation fails or update fails
    func updateFinancialPlan(_ plan: FinancialPlan) async throws {
        try validateFinancialPlan(plan)

        // Check for overlapping plans if active (excluding self)
        if plan.isActive {
            try await checkForOverlappingPlans(plan, excluding: plan.id)
        }

        try await planDataAccess.updateFinancialPlan(plan)

        // Refresh related data
        await refreshPerformanceSummary()
        await refreshFinancialHealthScore()
        await generatePlanRecommendations(for: plan)

        settingsManager.triggerHapticFeedback(.light)
    }

    /// Deletes a financial plan and all related data
    /// - Parameter id: The plan ID to delete
    /// - Throws: PlanRepositoryError if deletion fails
    func deleteFinancialPlan(by id: String) async throws {
        try await planDataAccess.deleteFinancialPlan(by: id)
        await refreshPerformanceSummary()
        await refreshFinancialHealthScore()
        settingsManager.triggerHapticFeedback(.medium)
    }

    /// Activates a plan and optionally deactivates others
    /// - Parameters:
    ///   - planId: The plan ID to activate
    ///   - deactivateOthers: Whether to deactivate other overlapping plans
    /// - Throws: PlanRepositoryError if activation fails
    func activatePlan(_ planId: String, deactivateOthers: Bool = true) async throws {
        try await planDataAccess.activatePlan(planId, deactivateOthers: deactivateOthers)
        await refreshPerformanceSummary()
        settingsManager.triggerHapticFeedback(.success)
    }

    /// Deactivates a plan
    /// - Parameter planId: The plan ID to deactivate
    /// - Throws: PlanRepositoryError if deactivation fails
    func deactivatePlan(_ planId: String) async throws {
        guard let plan = try await planDataAccess.getFinancialPlan(by: planId) else {
            throw PlanRepositoryError.planNotFound
        }

        let deactivatedPlan = plan.updated(with: ["isActive": false])
        try await planDataAccess.updateFinancialPlan(deactivatedPlan)
        await refreshPerformanceSummary()
        settingsManager.triggerHapticFeedback(.medium)
    }

    // MARK: - Public Methods - Plan Analysis and Calculation

    /// Calculates comprehensive plan performance for a plan
    /// - Parameter planId: The plan ID to analyze
    /// - Returns: PlanPerformanceSummary with detailed analysis
    func calculatePlanPerformance(for planId: String) async throws -> PlanPerformanceSummary {
        guard let plan = try await planDataAccess.getFinancialPlan(by: planId) else {
            throw PlanRepositoryError.planNotFound
        }

        let performanceData = try await planDataAccess.getPlanPerformanceSummary(for: planId)
        let monthlyTrends = try await planDataAccess.getMonthlyTrends(for: planId)

        return PlanPerformanceSummary(
            planId: planId,
            planName: plan.name,
            totalPlannedIncome: performanceData["totalPlannedIncome"] as? Double ?? 0,
            totalActualIncome: performanceData["totalActualIncome"] as? Double ?? 0,
            totalPlannedExpenses: performanceData["totalPlannedExpenses"] as? Double ?? 0,
            totalActualExpenses: performanceData["totalActualExpenses"] as? Double ?? 0,
            totalPlannedSavings: performanceData["totalPlannedSavings"] as? Double ?? 0,
            totalActualSavings: performanceData["totalActualSavings"] as? Double ?? 0,
            averageFinancialHealthScore: performanceData["averageFinancialHealthScore"] as? Double ?? 0,
            incomeVariance: performanceData["incomeVariance"] as? Double ?? 0,
            expenseVariance: performanceData["expenseVariance"] as? Double ?? 0,
            savingsVariance: performanceData["savingsVariance"] as? Double ?? 0,
            completedMonths: performanceData["completedMonths"] as? Int ?? 0,
            monthlyTrends: monthlyTrends,
            currency: settingsManager.currency
        )
    }

    /// Generates advanced financial projections for a plan
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - scenarioType: Type of scenario to project
    /// - Returns: FinancialProjection with detailed projections
    func generateFinancialProjections(for planId: String, scenario: ProjectionScenario = .realistic) async throws -> FinancialProjection {
        guard let plan = try await planDataAccess.getFinancialPlan(by: planId) else {
            throw PlanRepositoryError.planNotFound
        }

        let monthlyBreakdowns = try await planDataAccess.getMonthlyBreakdowns(for: planId)
        let currentDate = Date()
        let calendar = Calendar.current

        var projections: [MonthlyProjection] = []
        var currentValue = 0.0 // Net worth or savings value
        var cumulativeSavings = 0.0

        // Get scenario parameters
        let scenarioParams = getScenarioParameters(for: scenario, from: plan)

        // Project each month from current date to plan end date
        var projectionDate = max(currentDate, plan.startDate)
        let endDate = plan.endDate

        while projectionDate <= endDate {
            let monthKey = DateFormatter.monthKeyFormatter.string(from: projectionDate)

            // Get or create breakdown for this month
            let breakdown = monthlyBreakdowns.first { $0.month == monthKey } ??
                            createProjectedBreakdown(for: monthKey, plan: plan, scenario: scenarioParams)

            // Calculate projections based on scenario
            let projectedIncome = breakdown.plannedIncome * scenarioParams.incomeMultiplier
            let projectedExpenses = breakdown.plannedExpenses * scenarioParams.expenseMultiplier
            let projectedSavings = projectedIncome - projectedExpenses

            // Apply investment growth
            currentValue = currentValue * (1 + scenarioParams.monthlyGrowthRate) + projectedSavings
            cumulativeSavings += projectedSavings

            let monthlyProjection = MonthlyProjection(
                month: monthKey,
                projectedIncome: projectedIncome,
                projectedExpenses: projectedExpenses,
                projectedSavings: projectedSavings,
                cumulativeSavings: cumulativeSavings,
                investmentValue: currentValue,
                netWorth: currentValue // Simplified calculation
            )

            projections.append(monthlyProjection)

            // Move to next month
            projectionDate = calendar.date(byAdding: .month, value: 1, to: projectionDate) ?? endDate
        }

        return FinancialProjection(
            planId: planId,
            scenario: scenario,
            projections: projections,
            finalNetWorth: currentValue,
            totalSavings: cumulativeSavings,
            projectedRetirementAge: calculateProjectedRetirementAge(finalValue: currentValue, plan: plan),
            currency: settingsManager.currency
        )
    }

    /// Performs budget optimization analysis
    /// - Parameter planId: The plan ID to optimize
    /// - Returns: BudgetOptimization with optimization suggestions
    func optimizeBudget(for planId: String) async throws -> BudgetOptimization {
        guard let plan = try await planDataAccess.getFinancialPlan(by: planId) else {
            throw PlanRepositoryError.planNotFound
        }

        let monthlyBreakdowns = try await planDataAccess.getMonthlyBreakdowns(for: planId)
        let categoryPerformance = try await planDataAccess.getCategoryPerformance(for: planId)

        var optimizations: [BudgetOptimizationSuggestion] = []

        // Analyze category performance for optimization opportunities
        if let categoryData = categoryPerformance["categoryPerformance"] as? [String: [String: Double]] {
            for (categoryId, performance) in categoryData {
                let plannedBudget = performance["totalPlanned"] ?? 0
                let actualExpenses = performance["totalActual"] ?? 0
                let variance = performance["totalVariance"] ?? 0

                // Suggest optimizations based on variance patterns
                if variance > plannedBudget * 0.2 { // Over budget by 20%
                    optimizations.append(BudgetOptimizationSuggestion(
                        categoryId: categoryId,
                        type: .increaseBudget,
                        currentAmount: plannedBudget,
                        suggestedAmount: actualExpenses * 1.1, // 10% buffer
                        expectedSavings: 0,
                        reasoning: L("optimization_increase_budget_reasoning"),
                        priority: .medium
                    ))
                } else if variance < -plannedBudget * 0.15 { // Under budget by 15%
                    let potentialSavings = -variance * 0.5 // Redirect half the savings
                    optimizations.append(BudgetOptimizationSuggestion(
                        categoryId: categoryId,
                        type: .decreaseBudget,
                        currentAmount: plannedBudget,
                        suggestedAmount: plannedBudget + variance * 0.5,
                        expectedSavings: potentialSavings,
                        reasoning: L("optimization_decrease_budget_reasoning"),
                        priority: .low
                    ))
                }
            }
        }

        // Analyze savings rate optimization
        let currentSavingsRate = plan.savingsRate
        let recommendedSavingsRate = calculateRecommendedSavingsRate(for: plan)

        if recommendedSavingsRate > currentSavingsRate + 5 { // More than 5% improvement possible
            optimizations.append(BudgetOptimizationSuggestion(
                categoryId: "savings",
                type: .increaseSavings,
                currentAmount: plan.targetMonthlySavings,
                suggestedAmount: plan.averageMonthlyIncome * (recommendedSavingsRate / 100),
                expectedSavings: (recommendedSavingsRate - currentSavingsRate) / 100 * plan.averageMonthlyIncome,
                reasoning: L("optimization_increase_savings_reasoning"),
                priority: .high
            ))
        }

        return BudgetOptimization(
            planId: planId,
            currentBudgetEfficiency: calculateBudgetEfficiency(for: plan, breakdowns: monthlyBreakdowns),
            optimizedBudgetEfficiency: calculateOptimizedBudgetEfficiency(optimizations: optimizations),
            suggestions: optimizations.sorted { $0.priority.rawValue > $1.priority.rawValue },
            potentialMonthlySavings: optimizations.reduce(0) { $0 + $1.expectedSavings },
            currency: settingsManager.currency
        )
    }

    /// Calculates financial health score for a plan
    /// - Parameter planId: The plan ID to analyze
    /// - Returns: FinancialHealthAnalysis with detailed health metrics
    func calculateFinancialHealth(for planId: String) async throws -> FinancialHealthAnalysis {
        guard let plan = try await planDataAccess.getFinancialPlan(by: planId) else {
            throw PlanRepositoryError.planNotFound
        }

        let performanceSummary = try await calculatePlanPerformance(for: planId)
        let monthlyBreakdowns = try await planDataAccess.getMonthlyBreakdowns(for: planId)

        // Calculate various health metrics
        let savingsRateScore = calculateSavingsRateScore(plan.savingsRate)
        let budgetVarianceScore = calculateBudgetVarianceScore(from: performanceSummary)
        let emergencyFundScore = calculateEmergencyFundScore(for: plan)
        let debtToIncomeScore = calculateDebtToIncomeScore(for: plan)
        let diversificationScore = calculateDiversificationScore(from: monthlyBreakdowns)

        let healthMetrics = FinancialHealthMetrics(
            savingsRateScore: savingsRateScore,
            budgetVarianceScore: budgetVarianceScore,
            emergencyFundScore: emergencyFundScore,
            debtToIncomeScore: debtToIncomeScore,
            diversificationScore: diversificationScore
        )

        let overallScore = calculateOverallHealthScore(from: healthMetrics)

        return FinancialHealthAnalysis(
            planId: planId,
            overallScore: overallScore,
            metrics: healthMetrics,
            healthLevel: determineHealthLevel(from: overallScore),
            recommendations: generateHealthRecommendations(from: healthMetrics, plan: plan),
            lastUpdated: Date()
        )
    }

    // MARK: - Public Methods - Monthly Breakdown Management

    /// Updates monthly breakdown with actual data from expenses
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - month: Month string (YYYY-MM)
    /// - Throws: PlanRepositoryError if update fails
    func updateMonthlyBreakdownFromExpenses(planId: String, month: String) async throws {
        // Get expenses for the month
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        guard let monthDate = formatter.date(from: month) else {
            throw PlanRepositoryError.invalidMonth
        }

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthDate

        // Get expenses and calculate totals by category
        let monthExpenses = try await expenseRepository.getExpenses(
            startDate: monthStart,
            endDate: monthEnd,
            status: .confirmed
        )

        let categoryTotals = Dictionary(grouping: monthExpenses) { $0.categoryId }
            .mapValues { expenses in
                [
                    "totalAmount": expenses.totalAmount,
                    "transactionCount": expenses.count
                ]
            }

        let totalExpenses = monthExpenses.totalAmount

        let expenseData: [String: Any] = [
            "totalAmount": totalExpenses,
            "categoryBreakdown": categoryTotals
        ]

        try await planDataAccess.updateBreakdownFromExpenses(
            planId: planId,
            month: month,
            expenseData: expenseData
        )

        await updateCurrentMonthBreakdown()
        await refreshPerformanceSummary()
    }

    /// Completes a monthly breakdown and marks it as finalized
    /// - Parameters:
    ///   - planId: The plan ID
    ///   - month: Month string to complete
    ///   - actualIncome: Actual income for the month
    /// - Throws: PlanRepositoryError if completion fails
    func completeMonthlyBreakdown(planId: String, month: String, actualIncome: Double) async throws {
        guard let breakdown = try await planDataAccess.getMonthlyBreakdown(by: "\(planId)_\(month)") else {
            throw PlanRepositoryError.breakdownNotFound
        }

        // Update breakdown with actual income and mark as complete
        let completedBreakdown = breakdown.updated(with: [
            "actualIncome": actualIncome,
            "isCompleted": true,
            "actualSavings": max(actualIncome - breakdown.actualExpenses, 0)
        ])

        try await planDataAccess.updateMonthlyBreakdown(completedBreakdown)

        await refreshPerformanceSummary()
        await refreshFinancialHealthScore()
        settingsManager.triggerHapticFeedback(.success)
    }

    // MARK: - Public Methods - Plan Templates and Recommendations

    /// Generates plan recommendations based on user profile and financial data
    /// - Parameter userProfile: User's financial profile
    /// - Returns: Array of PlanRecommendation
    func generatePlanRecommendations(for userProfile: UserFinancialProfile? = nil) async throws -> [PlanRecommendation] {
        let profile = userProfile ?? await createUserProfileFromCurrentData()

        var recommendations: [PlanRecommendation] = []

        // Emergency fund recommendation
        if profile.emergencyFundMonths < 6 {
            recommendations.append(createEmergencyFundRecommendation(for: profile))
        }

        // Debt payoff recommendation
        if profile.totalDebt > 0 {
            recommendations.append(createDebtPayoffRecommendation(for: profile))
        }

        // Retirement savings recommendation
        if profile.retirementSavingsRate < 15 {
            recommendations.append(createRetirementSavingsRecommendation(for: profile))
        }

        // Investment diversification recommendation
        if profile.investmentDiversificationScore < 0.7 {
            recommendations.append(createInvestmentDiversificationRecommendation(for: profile))
        }

        // Budget optimization recommendation
        if profile.budgetEfficiencyScore < 0.8 {
            recommendations.append(createBudgetOptimizationRecommendation(for: profile))
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    /// Creates a plan from a template with user customization
    /// - Parameters:
    ///   - template: The plan template to use
    ///   - customization: User customization parameters
    /// - Returns: Customized FinancialPlan
    func createPlanFromTemplate(_ template: PlanTemplate, customization: PlanCustomization) -> FinancialPlan {
        let startDate = customization.startDate ?? Date()
        let endDate = Calendar.current.date(byAdding: .month, value: customization.durationMonths, to: startDate) ?? startDate
        let totalIncome = customization.monthlyIncome * Double(customization.durationMonths)

        let plan = FinancialPlan(
            name: customization.name,
            description: template.description,
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            totalBudget: totalIncome * template.budgetRatio,
            savingsGoal: totalIncome * template.savingsRatio,
            emergencyFundGoal: customization.monthlyIncome * Double(template.emergencyFundMonths),
            interestType: template.interestType,
            annualInterestRate: template.expectedReturnRate,
            compoundingFrequency: 12,
            currency: settingsManager.currency,
            categoryAllocations: template.categoryAllocations,
            fixedExpenses: customization.fixedExpenses,
            variableExpenseBudgets: calculateVariableBudgets(
                monthlyIncome: customization.monthlyIncome,
                fixedExpenses: customization.fixedExpenses,
                savingsRate: template.savingsRatio,
                allocations: template.categoryAllocations
            )
        )

        return plan
    }

    // MARK: - Public Methods - Data Management

    /// Refreshes all plan-related data
    func refreshAllData() async {
        await refreshPerformanceSummary()
        await refreshFinancialHealthScore()
        await updateCurrentMonthBreakdown()
        try? await generatePlanRecommendations()
    }

    /// Clears all cached data
    func clearCache() {
        financialPlans = []
        activePlans = []
        currentMonthBreakdown = nil
        planPerformanceSummary = nil
        planRecommendations = []
        financialHealthScore = 0.0
    }

    // MARK: - Private Methods - Business Logic

    private func validateFinancialPlan(_ plan: FinancialPlan) throws {
        guard !plan.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlanRepositoryError.missingPlanName
        }

        guard plan.startDate < plan.endDate else {
            throw PlanRepositoryError.invalidDateRange
        }

        guard plan.totalIncome > 0 else {
            throw PlanRepositoryError.invalidIncome
        }

        guard plan.savingsGoal >= 0 else {
            throw PlanRepositoryError.invalidSavingsGoal
        }

        guard plan.annualInterestRate >= 0 && plan.annualInterestRate <= 1 else {
            throw PlanRepositoryError.invalidInterestRate
        }

        // Validate budget allocations don't exceed income
        let totalAllocations = plan.categoryAllocations.values.reduce(0, +) +
                             plan.fixedExpenses.values.reduce(0, +) +
                             plan.variableExpenseBudgets.values.reduce(0, +)

        if totalAllocations > plan.averageMonthlyIncome * 1.05 { // 5% tolerance
            throw PlanRepositoryError.budgetExceedsIncome
        }
    }

    private func enhancePlanWithSettings(_ plan: FinancialPlan) -> FinancialPlan {
        return plan.updated(with: [
            "currency": settingsManager.currency
        ])
    }

    private func checkForOverlappingPlans(_ plan: FinancialPlan, excluding excludeId: String? = nil) async throws {
        let existingPlans = try await planDataAccess.getAllFinancialPlans(includeInactive: false)

        for existingPlan in existingPlans {
            if let excludeId = excludeId, existingPlan.id == excludeId {
                continue
            }

            if existingPlan.isActive &&
               plansOverlap(plan1: plan, plan2: existingPlan) {
                throw PlanRepositoryError.overlappingActivePlans
            }
        }
    }

    private func plansOverlap(plan1: FinancialPlan, plan2: FinancialPlan) -> Bool {
        return plan1.startDate <= plan2.endDate && plan1.endDate >= plan2.startDate
    }

    private func generatePlanRecommendations(for plan: FinancialPlan) async {
        // This would generate specific recommendations for the plan
        // Implementation would analyze the plan and create recommendations
        // For now, just update the recommendations array
        do {
            let recommendations = try await generatePlanRecommendations()
            await MainActor.run {
                self.planRecommendations = recommendations
            }
        } catch {
            print("Failed to generate plan recommendations: \(error)")
        }
    }

    private func updateDerivedData() {
        // Update any derived data when financial plans change
        Task {
            await updateCurrentMonthBreakdown()
            await refreshFinancialHealthScore()
        }
    }

    private func updateCurrentMonthBreakdown() async {
        guard let activePlan = activePlans.first else {
            await MainActor.run {
                self.currentMonthBreakdown = nil
            }
            return
        }

        let currentMonth = DateFormatter.monthKeyFormatter.string(from: Date())

        do {
            let breakdowns = try await planDataAccess.getMonthlyBreakdowns(for: activePlan.id)
            let currentBreakdown = breakdowns.first { $0.month == currentMonth }

            await MainActor.run {
                self.currentMonthBreakdown = currentBreakdown
            }
        } catch {
            print("Failed to update current month breakdown: \(error)")
        }
    }

    private func refreshPerformanceSummary() async {
        guard let activePlan = activePlans.first else {
            await MainActor.run {
                self.planPerformanceSummary = nil
            }
            return
        }

        do {
            let summary = try await calculatePlanPerformance(for: activePlan.id)
            await MainActor.run {
                self.planPerformanceSummary = summary
            }
        } catch {
            print("Failed to refresh performance summary: \(error)")
        }
    }

    private func refreshFinancialHealthScore() async {
        guard let activePlan = activePlans.first else {
            await MainActor.run {
                self.financialHealthScore = 0.0
            }
            return
        }

        do {
            let healthAnalysis = try await calculateFinancialHealth(for: activePlan.id)
            await MainActor.run {
                self.financialHealthScore = healthAnalysis.overallScore
            }
        } catch {
            print("Failed to refresh financial health score: \(error)")
        }
    }

    // MARK: - Private Methods - Calculations

    private func getScenarioParameters(for scenario: ProjectionScenario, from plan: FinancialPlan) -> ScenarioParameters {
        switch scenario {
        case .optimistic:
            return ScenarioParameters(
                incomeMultiplier: 1.1,
                expenseMultiplier: 0.95,
                monthlyGrowthRate: plan.annualInterestRate / 12 * 1.2
            )
        case .realistic:
            return ScenarioParameters(
                incomeMultiplier: 1.0,
                expenseMultiplier: 1.0,
                monthlyGrowthRate: plan.annualInterestRate / 12
            )
        case .pessimistic:
            return ScenarioParameters(
                incomeMultiplier: 0.9,
                expenseMultiplier: 1.1,
                monthlyGrowthRate: plan.annualInterestRate / 12 * 0.7
            )
        }
    }

    private func createProjectedBreakdown(for month: String, plan: FinancialPlan, scenario: ScenarioParameters) -> PlanMonthlyBreakdown {
        // Create a projected breakdown based on plan averages
        return PlanMonthlyBreakdown(
            id: "\(plan.id)_\(month)_projected",
            planId: plan.id,
            month: month,
            year: Int(month.prefix(4)) ?? Calendar.current.component(.year, from: Date()),
            monthNumber: Int(month.suffix(2)) ?? 1,
            plannedIncome: plan.averageMonthlyIncome,
            actualIncome: 0.0,
            plannedExpenses: plan.averageMonthlyBudget,
            actualExpenses: 0.0,
            plannedSavings: plan.targetMonthlySavings,
            actualSavings: 0.0,
            categoryBreakdown: [:],
            notes: L("projected_breakdown_note"),
            isCompleted: false
        )
    }

    private func calculateProjectedRetirementAge(finalValue: Double, plan: FinancialPlan) -> Int? {
        // Simplified retirement age calculation
        // This would need more sophisticated logic in practice
        let retirementTarget = plan.averageMonthlyIncome * 12 * 25 // 25x annual income rule

        if finalValue >= retirementTarget {
            let currentAge = 30 // This would be from user profile
            let yearsToRetirement = plan.durationInYears
            return currentAge + Int(yearsToRetirement)
        }

        return nil
    }

    private func calculateRecommendedSavingsRate(for plan: FinancialPlan) -> Double {
        // Calculate recommended savings rate based on plan goals and timeline
        let yearsToGoal = plan.durationInYears
        let targetAmount = plan.savingsGoal
        let monthlyIncome = plan.averageMonthlyIncome

        // Use future value of annuity calculation
        let monthlyRate = plan.annualInterestRate / 12
        let totalMonths = yearsToGoal * 12

        if monthlyRate > 0 {
            let factor = (pow(1 + monthlyRate, totalMonths) - 1) / monthlyRate
            let requiredMonthlySavings = targetAmount / factor
            return (requiredMonthlySavings / monthlyIncome) * 100
        } else {
            return (targetAmount / (monthlyIncome * totalMonths)) * 100
        }
    }

    private func calculateBudgetEfficiency(for plan: FinancialPlan, breakdowns: [PlanMonthlyBreakdown]) -> Double {
        guard !breakdowns.isEmpty else { return 0.0 }

        let completedBreakdowns = breakdowns.filter { $0.isCompleted }
        guard !completedBreakdowns.isEmpty else { return 0.0 }

        let efficiencyScores = completedBreakdowns.map { breakdown in
            let budgetAccuracy = 1.0 - abs(breakdown.expenseVariance) / max(breakdown.plannedExpenses, 1.0)
            let savingsEfficiency = breakdown.actualSavings / max(breakdown.plannedSavings, 1.0)
            return (budgetAccuracy + min(savingsEfficiency, 1.0)) / 2.0
        }

        return efficiencyScores.reduce(0, +) / Double(efficiencyScores.count)
    }

    private func calculateOptimizedBudgetEfficiency(optimizations: [BudgetOptimizationSuggestion]) -> Double {
        // Estimate efficiency improvement from optimizations
        let totalSavings = optimizations.reduce(0) { $0 + $1.expectedSavings }
        let highPriorityCount = optimizations.filter { $0.priority == .high }.count

        // Simple heuristic: each optimization adds efficiency
        let baseImprovement = min(Double(optimizations.count) * 0.05, 0.3) // Max 30% improvement
        let priorityBonus = Double(highPriorityCount) * 0.02

        return min(baseImprovement + priorityBonus, 1.0)
    }

    // MARK: - Private Methods - Health Calculations

    private func calculateSavingsRateScore(_ savingsRate: Double) -> Double {
        // Score based on common savings rate recommendations
        switch savingsRate {
        case 0..<10: return 0.4
        case 10..<15: return 0.6
        case 15..<20: return 0.8
        case 20..<30: return 1.0
        default: return 0.9 // Very high savings rate might indicate over-saving
        }
    }

    private func calculateBudgetVarianceScore(from summary: PlanPerformanceSummary) -> Double {
        let expenseVariancePercent = abs(summary.expenseVariance) / max(summary.totalPlannedExpenses, 1.0) * 100

        switch expenseVariancePercent {
        case 0..<5: return 1.0
        case 5..<10: return 0.8
        case 10..<20: return 0.6
        case 20..<30: return 0.4
        default: return 0.2
        }
    }

    private func calculateEmergencyFundScore(for plan: FinancialPlan) -> Double {
        let monthsCovered = plan.emergencyFundGoal / plan.averageMonthlyBudget

        switch monthsCovered {
        case 0..<1: return 0.0
        case 1..<3: return 0.3
        case 3..<6: return 0.7
        case 6...: return 1.0
        default: return 0.0
        }
    }

    private func calculateDebtToIncomeScore(for plan: FinancialPlan) -> Double {
        // Simplified calculation - would need actual debt data
        let assumedDebtPayments = plan.fixedExpenses.values.filter { $0 > plan.averageMonthlyIncome * 0.1 }.reduce(0, +)
        let debtToIncomeRatio = assumedDebtPayments / plan.averageMonthlyIncome

        switch debtToIncomeRatio {
        case 0..<0.1: return 1.0
        case 0.1..<0.2: return 0.8
        case 0.2..<0.36: return 0.6
        case 0.36..<0.5: return 0.4
        default: return 0.2
        }
    }

    private func calculateDiversificationScore(from breakdowns: [PlanMonthlyBreakdown]) -> Double {
        // Calculate based on category distribution variance
        guard !breakdowns.isEmpty else { return 0.0 }

        var categoryTotals: [String: Double] = [:]
        for breakdown in breakdowns {
            for (categoryId, categoryData) in breakdown.categoryBreakdown {
                categoryTotals[categoryId, default: 0] += categoryData.actualExpenses
            }
        }

        let totalExpenses = categoryTotals.values.reduce(0, +)
        guard totalExpenses > 0 else { return 0.0 }

        let categoryPercentages = categoryTotals.mapValues { $0 / totalExpenses }
        let uniqueCategories = categoryPercentages.count

        // Score based on number of categories and distribution
        switch uniqueCategories {
        case 0..<3: return 0.3
        case 3..<5: return 0.6
        case 5..<8: return 0.8
        case 8...: return 1.0
        default: return 0.0
        }
    }

    private func calculateOverallHealthScore(from metrics: FinancialHealthMetrics) -> Double {
        let weights: [Double] = [0.25, 0.2, 0.2, 0.2, 0.15] // Sum to 1.0
        let scores = [
            metrics.savingsRateScore,
            metrics.budgetVarianceScore,
            metrics.emergencyFundScore,
            metrics.debtToIncomeScore,
            metrics.diversificationScore
        ]

        return zip(scores, weights).reduce(0.0) { $0 + $1.0 * $1.1 } * 100
    }

    private func determineHealthLevel(from score: Double) -> FinancialHealthLevel {
        switch score {
        case 0..<40: return .poor
        case 40..<60: return .fair
        case 60..<80: return .good
        case 80...: return .excellent
        default: return .poor
        }
    }

    private func generateHealthRecommendations(from metrics: FinancialHealthMetrics, plan: FinancialPlan) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []

        if metrics.savingsRateScore < 0.7 {
            recommendations.append(HealthRecommendation(
                type: .increaseSavingsRate,
                title: L("health_recommendation_increase_savings_title"),
                description: L("health_recommendation_increase_savings_description"),
                priority: .high
            ))
        }

        if metrics.emergencyFundScore < 0.7 {
            recommendations.append(HealthRecommendation(
                type: .buildEmergencyFund,
                title: L("health_recommendation_emergency_fund_title"),
                description: L("health_recommendation_emergency_fund_description"),
                priority: .high
            ))
        }

        if metrics.budgetVarianceScore < 0.6 {
            recommendations.append(HealthRecommendation(
                type: .improveBudgetAccuracy,
                title: L("health_recommendation_budget_accuracy_title"),
                description: L("health_recommendation_budget_accuracy_description"),
                priority: .medium
            ))
        }

        return recommendations
    }

    // MARK: - Private Methods - Plan Templates

    private func createUserProfileFromCurrentData() async -> UserFinancialProfile {
        // Create a user profile based on current app data
        let currentSummary = try? await expenseRepository.getCurrentSpendingSummary()

        return UserFinancialProfile(
            monthlyIncome: currentSummary?.monthlyLimit ?? 5000,
            monthlyExpenses: currentSummary?.thisMonth ?? 3000,
            currentSavings: 0, // Would be from savings tracking
            totalDebt: 0, // Would be from debt tracking
            emergencyFundMonths: 3, // Default assumption
            retirementSavingsRate: 10, // Default assumption
            investmentDiversificationScore: 0.5,
            budgetEfficiencyScore: 0.7,
            riskTolerance: .moderate
        )
    }

    private func createEmergencyFundRecommendation(for profile: UserFinancialProfile) -> PlanRecommendation {
        let targetAmount = profile.monthlyExpenses * 6
        let currentAmount = profile.monthlyExpenses * profile.emergencyFundMonths
        let needed = targetAmount - currentAmount
        let monthsToGoal = max(Int(needed / (profile.monthlyIncome * 0.1)), 6) // 10% of income towards emergency fund

        return PlanRecommendation(
            type: .emergencyFund,
            title: L("recommendation_emergency_fund_title"),
            description: L("recommendation_emergency_fund_description"),
            priority: .high,
            estimatedMonths: monthsToGoal,
            targetAmount: targetAmount,
            monthlySavingsRequired: needed / Double(monthsToGoal)
        )
    }

    private func createDebtPayoffRecommendation(for profile: UserFinancialProfile) -> PlanRecommendation {
        let monthlyPayment = profile.monthlyIncome * 0.2 // 20% towards debt
        let monthsToPayoff = Int(ceil(profile.totalDebt / monthlyPayment))

        return PlanRecommendation(
            type: .debtPayoff,
            title: L("recommendation_debt_payoff_title"),
            description: L("recommendation_debt_payoff_description"),
            priority: .high,
            estimatedMonths: monthsToPayoff,
            targetAmount: 0, // Goal is to reach 0 debt
            monthlySavingsRequired: monthlyPayment
        )
    }

    private func createRetirementSavingsRecommendation(for profile: UserFinancialProfile) -> PlanRecommendation {
        let recommendedRate = 15.0 // 15% for retirement
        let currentSavings = profile.monthlyIncome * (profile.retirementSavingsRate / 100)
        let recommendedSavings = profile.monthlyIncome * (recommendedRate / 100)
        let additionalSavings = recommendedSavings - currentSavings

        return PlanRecommendation(
            type: .retirementSavings,
            title: L("recommendation_retirement_savings_title"),
            description: L("recommendation_retirement_savings_description"),
            priority: .medium,
            estimatedMonths: 360, // 30 years
            targetAmount: recommendedSavings * 360, // Simplified
            monthlySavingsRequired: additionalSavings
        )
    }

    private func createInvestmentDiversificationRecommendation(for profile: UserFinancialProfile) -> PlanRecommendation {
        return PlanRecommendation(
            type: .investmentDiversification,
            title: L("recommendation_investment_diversification_title"),
            description: L("recommendation_investment_diversification_description"),
            priority: .medium,
            estimatedMonths: 12,
            targetAmount: profile.currentSavings * 0.8, // 80% in diversified investments
            monthlySavingsRequired: 0
        )
    }

    private func createBudgetOptimizationRecommendation(for profile: UserFinancialProfile) -> PlanRecommendation {
        let potentialSavings = profile.monthlyExpenses * 0.1 // 10% optimization potential

        return PlanRecommendation(
            type: .budgetOptimization,
            title: L("recommendation_budget_optimization_title"),
            description: L("recommendation_budget_optimization_description"),
            priority: .low,
            estimatedMonths: 3,
            targetAmount: potentialSavings * 12, // Annual savings
            monthlySavingsRequired: potentialSavings
        )
    }

    private func calculateVariableBudgets(
        monthlyIncome: Double,
        fixedExpenses: [String: Double],
        savingsRate: Double,
        allocations: [String: Double]
    ) -> [String: Double] {
        let totalFixed = fixedExpenses.values.reduce(0, +)
        let totalSavings = monthlyIncome * savingsRate
        let availableForVariable = monthlyIncome - totalFixed - totalSavings

        var variableBudgets: [String: Double] = [:]
        let totalAllocationPercent = allocations.values.reduce(0, +)

        for (categoryId, percentage) in allocations {
            let normalizedPercentage = percentage / totalAllocationPercent
            variableBudgets[categoryId] = availableForVariable * normalizedPercentage
        }

        return variableBudgets
    }
}

// MARK: - Supporting Types and Extensions

extension DateFormatter {
    static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}

// MARK: - Supporting Types

/// Plan repository specific errors
enum PlanRepositoryError: LocalizedError {
    case missingPlanName
    case invalidDateRange
    case invalidIncome
    case invalidSavingsGoal
    case invalidInterestRate
    case budgetExceedsIncome
    case overlappingActivePlans
    case planNotFound
    case breakdownNotFound
    case invalidMonth

    var errorDescription: String? {
        switch self {
        case .missingPlanName:
            return L("error_missing_plan_name")
        case .invalidDateRange:
            return L("error_invalid_date_range")
        case .invalidIncome:
            return L("error_invalid_income")
        case .invalidSavingsGoal:
            return L("error_invalid_savings_goal")
        case .invalidInterestRate:
            return L("error_invalid_interest_rate")
        case .budgetExceedsIncome:
            return L("error_budget_exceeds_income")
        case .overlappingActivePlans:
            return L("error_overlapping_active_plans")
        case .planNotFound:
            return L("error_plan_not_found")
        case .breakdownNotFound:
            return L("error_breakdown_not_found")
        case .invalidMonth:
            return L("error_invalid_month")
        }
    }
}

/// Comprehensive plan performance summary
struct PlanPerformanceSummary {
    let planId: String
    let planName: String
    let totalPlannedIncome: Double
    let totalActualIncome: Double
    let totalPlannedExpenses: Double
    let totalActualExpenses: Double
    let totalPlannedSavings: Double
    let totalActualSavings: Double
    let averageFinancialHealthScore: Double
    let incomeVariance: Double
    let expenseVariance: Double
    let savingsVariance: Double
    let completedMonths: Int
    let monthlyTrends: [String: Any]
    let currency: String

    var incomeAchievementPercentage: Double {
        guard totalPlannedIncome > 0 else { return 0 }
        return (totalActualIncome / totalPlannedIncome) * 100
    }

    var expenseControlPercentage: Double {
        guard totalPlannedExpenses > 0 else { return 100 }
        return max(0, (1 - (totalActualExpenses / totalPlannedExpenses)) * 100)
    }

    var savingsAchievementPercentage: Double {
        guard totalPlannedSavings > 0 else { return 0 }
        return (totalActualSavings / totalPlannedSavings) * 100
    }
}

/// Financial projection scenarios
enum ProjectionScenario: String, CaseIterable {
    case optimistic = "optimistic"
    case realistic = "realistic"
    case pessimistic = "pessimistic"

    var displayName: String {
        switch self {
        case .optimistic:
            return L("scenario_optimistic")
        case .realistic:
            return L("scenario_realistic")
        case .pessimistic:
            return L("scenario_pessimistic")
        }
    }
}

/// Scenario calculation parameters
struct ScenarioParameters {
    let incomeMultiplier: Double
    let expenseMultiplier: Double
    let monthlyGrowthRate: Double
}

/// Financial projection result
struct FinancialProjection {
    let planId: String
    let scenario: ProjectionScenario
    let projections: [MonthlyProjection]
    let finalNetWorth: Double
    let totalSavings: Double
    let projectedRetirementAge: Int?
    let currency: String
}

/// Monthly projection data
struct MonthlyProjection {
    let month: String
    let projectedIncome: Double
    let projectedExpenses: Double
    let projectedSavings: Double
    let cumulativeSavings: Double
    let investmentValue: Double
    let netWorth: Double
}

/// Budget optimization analysis
struct BudgetOptimization {
    let planId: String
    let currentBudgetEfficiency: Double
    let optimizedBudgetEfficiency: Double
    let suggestions: [BudgetOptimizationSuggestion]
    let potentialMonthlySavings: Double
    let currency: String
}

/// Budget optimization suggestion
struct BudgetOptimizationSuggestion {
    let categoryId: String
    let type: OptimizationType
    let currentAmount: Double
    let suggestedAmount: Double
    let expectedSavings: Double
    let reasoning: String
    let priority: OptimizationPriority
}

/// Optimization types
enum OptimizationType {
    case increaseBudget
    case decreaseBudget
    case increaseSavings
    case reallocateFunds
}

/// Optimization priority levels
enum OptimizationPriority: Int {
    case low = 1
    case medium = 2
    case high = 3
}

/// Financial health analysis
struct FinancialHealthAnalysis {
    let planId: String
    let overallScore: Double
    let metrics: FinancialHealthMetrics
    let healthLevel: FinancialHealthLevel
    let recommendations: [HealthRecommendation]
    let lastUpdated: Date
}

/// Financial health metrics
struct FinancialHealthMetrics {
    let savingsRateScore: Double
    let budgetVarianceScore: Double
    let emergencyFundScore: Double
    let debtToIncomeScore: Double
    let diversificationScore: Double
}

/// Financial health levels
enum FinancialHealthLevel {
    case poor
    case fair
    case good
    case excellent

    var displayName: String {
        switch self {
        case .poor:
            return L("health_level_poor")
        case .fair:
            return L("health_level_fair")
        case .good:
            return L("health_level_good")
        case .excellent:
            return L("health_level_excellent")
        }
    }

    var color: Color {
        switch self {
        case .poor:
            return .red
        case .fair:
            return .orange
        case .good:
            return .green
        case .excellent:
            return .blue
        }
    }
}

/// Health recommendation
struct HealthRecommendation {
    let type: HealthRecommendationType
    let title: String
    let description: String
    let priority: OptimizationPriority
}

/// Health recommendation types
enum HealthRecommendationType {
    case increaseSavingsRate
    case buildEmergencyFund
    case improveBudgetAccuracy
    case reduceDebt
    case diversifyInvestments
}

/// Plan recommendation
struct PlanRecommendation {
    let type: PlanRecommendationType
    let title: String
    let description: String
    let priority: OptimizationPriority
    let estimatedMonths: Int
    let targetAmount: Double
    let monthlySavingsRequired: Double
}

/// Plan recommendation types
enum PlanRecommendationType {
    case emergencyFund
    case debtPayoff
    case retirementSavings
    case investmentDiversification
    case budgetOptimization
}

/// User financial profile for recommendations
struct UserFinancialProfile {
    let monthlyIncome: Double
    let monthlyExpenses: Double
    let currentSavings: Double
    let totalDebt: Double
    let emergencyFundMonths: Double
    let retirementSavingsRate: Double
    let investmentDiversificationScore: Double
    let budgetEfficiencyScore: Double
    let riskTolerance: RiskTolerance
}

/// Risk tolerance levels
enum RiskTolerance {
    case conservative
    case moderate
    case aggressive
}

/// Plan template for quick plan creation
struct PlanTemplate {
    let name: String
    let description: String
    let budgetRatio: Double
    let savingsRatio: Double
    let emergencyFundMonths: Int
    let interestType: InterestType
    let expectedReturnRate: Double
    let categoryAllocations: [String: Double]
}

/// Plan customization parameters
struct PlanCustomization {
    let name: String
    let monthlyIncome: Double
    let durationMonths: Int
    let startDate: Date?
    let fixedExpenses: [String: Double]
}

// MARK: - Preview Helper

#if DEBUG
extension PlanRepository {
    static let preview: PlanRepository = {
        return PlanRepository(
            planDataAccess: PlanDataAccess.preview,
            expenseRepository: ExpenseRepository.preview,
            categoryRepository: CategoryRepository.preview,
            settingsManager: SettingsManager.preview
        )
    }()
}
#endif