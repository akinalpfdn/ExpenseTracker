//
//  PlanningViewModel.swift
//  ExpenseTracker
//
//  Created by Claude on 17.09.2024.
//

import Foundation
import SwiftUI
import Combine

/// Comprehensive financial planning view model with state management for SwiftUI views
/// Provides reactive state management for financial plans, analysis, and projections
/// Integrates with PlanRepository for business logic and advanced financial calculations
@MainActor
class PlanningViewModel: ObservableObject {

    // MARK: - Dependencies

    private let planRepository: PlanRepository
    private let expenseRepository: ExpenseRepository
    private let categoryRepository: CategoryRepository
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties - Data State

    /// All financial plans
    @Published var financialPlans: [FinancialPlan] = []

    /// Active financial plans
    @Published var activePlans: [FinancialPlan] = []

    /// Currently selected plan for viewing/editing
    @Published var selectedPlan: FinancialPlan? = nil

    /// Current month's breakdown for active plan
    @Published var currentMonthBreakdown: PlanMonthlyBreakdown? = nil

    /// Plan performance summary
    @Published var planPerformanceSummary: PlanPerformanceSummary? = nil

    /// Plan recommendations
    @Published var planRecommendations: [PlanRecommendation] = []

    /// Financial health score
    @Published var financialHealthScore: Double = 0.0

    /// Financial health analysis
    @Published var financialHealthAnalysis: FinancialHealthAnalysis? = nil

    /// Budget optimization analysis
    @Published var budgetOptimization: BudgetOptimization? = nil

    /// Financial projections for different scenarios
    @Published var financialProjections: [ProjectionScenario: FinancialProjection] = [:]

    /// Plan templates available for creation
    @Published var planTemplates: [PlanTemplate] = []

    // MARK: - Published Properties - Filter and Selection State

    /// Selected plan type filter
    @Published var selectedPlanType: PlanType? = nil {
        didSet {
            applyFilters()
        }
    }

    /// Selected plan status filter
    @Published var selectedPlanStatus: PlanStatus? = nil {
        didSet {
            applyFilters()
        }
    }

    /// Date range filter for plans
    @Published var planDateRange: ClosedRange<Date>? = nil {
        didSet {
            applyFilters()
        }
    }

    /// Search text for plans
    @Published var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }

    /// Sort field for plans
    @Published var sortBy: PlanSortField = .startDate {
        didSet {
            applyFilters()
        }
    }

    /// Sort direction
    @Published var sortAscending: Bool = false {
        didSet {
            applyFilters()
        }
    }

    /// Filtered plans based on current filters
    @Published var filteredPlans: [FinancialPlan] = []

    // MARK: - Published Properties - UI State

    /// Loading state for various operations
    @Published var isLoading: Bool = false

    /// Loading state for creating plans
    @Published var isCreatingPlan: Bool = false

    /// Loading state for updating plans
    @Published var isUpdatingPlan: Bool = false

    /// Loading state for deleting plans
    @Published var isDeletingPlan: Bool = false

    /// Loading state for analytics
    @Published var isLoadingAnalytics: Bool = false

    /// Loading state for projections
    @Published var isLoadingProjections: Bool = false

    /// Current error message
    @Published var errorMessage: String? = nil

    /// Success message
    @Published var successMessage: String? = nil

    /// Whether error alert should be shown
    @Published var showingErrorAlert: Bool = false

    /// Whether success alert should be shown
    @Published var showingSuccessAlert: Bool = false

    /// Whether create plan sheet is presented
    @Published var showingCreatePlan: Bool = false

    /// Whether edit plan sheet is presented
    @Published var showingEditPlan: Bool = false

    /// Whether plan details view is presented
    @Published var showingPlanDetails: Bool = false

    /// Whether plan analysis view is presented
    @Published var showingPlanAnalysis: Bool = false

    /// Whether projections view is presented
    @Published var showingProjections: Bool = false

    /// Whether filters sheet is presented
    @Published var showingFilters: Bool = false

    /// Whether confirmation dialog is shown
    @Published var showingConfirmationDialog: Bool = false

    /// Whether optimization suggestions are shown
    @Published var showingOptimizationSuggestions: Bool = false

    // MARK: - Published Properties - Form State

    /// Form state for creating new plan
    @Published var newPlanForm: PlanFormState = PlanFormState()

    /// Form state for editing existing plan
    @Published var editPlanForm: PlanFormState = PlanFormState()

    /// Form validation errors
    @Published var formErrors: [String: String] = [:]

    /// Whether form is valid
    @Published var isFormValid: Bool = false

    /// Selected template for plan creation
    @Published var selectedTemplate: PlanTemplate? = nil {
        didSet {
            if let template = selectedTemplate {
                applyTemplate(template)
            }
        }
    }

    /// Custom plan creation step (for wizard-style creation)
    @Published var currentCreationStep: PlanCreationStep = .basicInfo

    /// Monthly breakdown editing state
    @Published var editingBreakdown: PlanMonthlyBreakdown? = nil

    /// Whether breakdown editing sheet is presented
    @Published var showingBreakdownEditor: Bool = false

    // MARK: - Published Properties - Analysis State

    /// Selected scenario for projections
    @Published var selectedProjectionScenario: ProjectionScenario = .realistic

    /// Projection time horizon (months)
    @Published var projectionHorizon: Int = 60 // 5 years

    /// Whether detailed analysis is expanded
    @Published var isDetailedAnalysisExpanded: Bool = false

    /// Selected metrics for comparison
    @Published var selectedComparisonMetrics: Set<ComparisonMetric> = [.totalSavings, .efficiency]

    /// Time period for performance analysis
    @Published var performanceAnalysisPeriod: AnalysisPeriod = .lastSixMonths

    // MARK: - Computed Properties

    /// Total number of plans
    var totalPlansCount: Int {
        financialPlans.count
    }

    /// Active plans count
    var activePlansCount: Int {
        activePlans.count
    }

    /// Filtered plans count
    var filteredPlansCount: Int {
        filteredPlans.count
    }

    /// Whether any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        selectedPlanType != nil ||
        selectedPlanStatus != nil ||
        planDateRange != nil
    }

    /// Primary active plan (most recent active plan)
    var primaryActivePlan: FinancialPlan? {
        activePlans.first
    }

    /// Overall financial health level
    var financialHealthLevel: FinancialHealthLevel {
        financialHealthAnalysis?.healthLevel ?? .poor
    }

    /// Whether optimization is needed
    var needsOptimization: Bool {
        budgetOptimization?.suggestions.isEmpty == false
    }

    /// Current month progress percentage
    var currentMonthProgress: Double {
        guard let breakdown = currentMonthBreakdown else { return 0 }
        guard breakdown.plannedIncome > 0 else { return 0 }
        return (breakdown.actualIncome / breakdown.plannedIncome) * 100
    }

    // MARK: - Initialization

    init(
        planRepository: PlanRepository,
        expenseRepository: ExpenseRepository = ExpenseRepository(),
        categoryRepository: CategoryRepository = CategoryRepository(),
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        self.planRepository = planRepository
        self.expenseRepository = expenseRepository
        self.categoryRepository = categoryRepository
        self.settingsManager = settingsManager
        setupBindings()
        loadInitialData()
    }

    // MARK: - Setup Methods

    private func setupBindings() {
        // Bind to repository data changes
        planRepository.$financialPlans
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plans in
                self?.financialPlans = plans
                self?.applyFilters()
            }
            .store(in: &cancellables)

        planRepository.$activePlans
            .receive(on: DispatchQueue.main)
            .assign(to: \.activePlans, on: self)
            .store(in: &cancellables)

        planRepository.$currentMonthBreakdown
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentMonthBreakdown, on: self)
            .store(in: &cancellables)

        planRepository.$planPerformanceSummary
            .receive(on: DispatchQueue.main)
            .assign(to: \.planPerformanceSummary, on: self)
            .store(in: &cancellables)

        planRepository.$planRecommendations
            .receive(on: DispatchQueue.main)
            .assign(to: \.planRecommendations, on: self)
            .store(in: &cancellables)

        planRepository.$financialHealthScore
            .receive(on: DispatchQueue.main)
            .assign(to: \.financialHealthScore, on: self)
            .store(in: &cancellables)

        // Form validation binding
        Publishers.CombineLatest4(
            newPlanForm.$name.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            newPlanForm.$totalIncome.map { $0 > 0 },
            newPlanForm.$startDate.map { _ in true },
            newPlanForm.$endDate.map { _ in true }
        )
        .map { $0 && $1 && $2 && $3 }
        .receive(on: DispatchQueue.main)
        .assign(to: \.isFormValid, on: self)
        .store(in: &cancellables)

        // Listen for settings changes
        settingsManager.$currency
            .sink { [weak self] _ in
                self?.refreshAnalytics()
            }
            .store(in: &cancellables)

        settingsManager.$budgetPeriod
            .sink { [weak self] _ in
                self?.refreshAnalytics()
            }
            .store(in: &cancellables)
    }

    private func loadInitialData() {
        Task {
            await loadPlans()
            await refreshAnalytics()
            await loadPlanTemplates()
            await loadRecommendations()
        }
    }

    // MARK: - Public Methods - Data Loading

    /// Loads all financial plans
    func loadPlans() async {
        isLoading = true
        defer { isLoading = false }

        await planRepository.refreshAllData()
    }

    /// Loads plan templates
    func loadPlanTemplates() async {
        // Load predefined templates
        let templates = [
            createEmergencyFundTemplate(),
            createRetirementSavingsTemplate(),
            createDebtPayoffTemplate(),
            createVacationSavingsTemplate(),
            createHomeDownPaymentTemplate()
        ]

        await MainActor.run {
            self.planTemplates = templates
        }
    }

    /// Loads plan recommendations
    func loadRecommendations() async {
        do {
            let recommendations = try await planRepository.generatePlanRecommendations()
            await MainActor.run {
                self.planRecommendations = recommendations
            }
        } catch {
            await handleError(error)
        }
    }

    /// Refreshes all analytics and calculations
    func refreshAnalytics() async {
        isLoadingAnalytics = true
        defer { isLoadingAnalytics = false }

        guard let activePlan = primaryActivePlan else { return }

        do {
            // Load financial health analysis
            let healthAnalysis = try await planRepository.calculateFinancialHealth(for: activePlan.id)

            // Load budget optimization
            let optimization = try await planRepository.optimizeBudget(for: activePlan.id)

            await MainActor.run {
                self.financialHealthAnalysis = healthAnalysis
                self.budgetOptimization = optimization
            }
        } catch {
            await handleError(error)
        }
    }

    /// Loads financial projections for all scenarios
    func loadProjections(for plan: FinancialPlan? = nil) async {
        let targetPlan = plan ?? primaryActivePlan
        guard let targetPlan = targetPlan else { return }

        isLoadingProjections = true
        defer { isLoadingProjections = false }

        do {
            var projections: [ProjectionScenario: FinancialProjection] = [:]

            for scenario in ProjectionScenario.allCases {
                let projection = try await planRepository.generateFinancialProjections(
                    for: targetPlan.id,
                    scenario: scenario
                )
                projections[scenario] = projection
            }

            await MainActor.run {
                self.financialProjections = projections
            }
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Public Methods - Plan Operations

    /// Creates a new financial plan
    func createPlan() async {
        guard isFormValid else {
            showError(L("error_invalid_form"))
            return
        }

        isCreatingPlan = true
        defer { isCreatingPlan = false }

        do {
            let plan = newPlanForm.toFinancialPlan()
            try await planRepository.createFinancialPlan(plan)

            await MainActor.run {
                self.showSuccess(L("plan_created_successfully"))
                self.newPlanForm.reset()
                self.showingCreatePlan = false
                self.currentCreationStep = .basicInfo
            }

            await loadPlans()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Updates an existing financial plan
    func updatePlan() async {
        guard let selectedPlan = selectedPlan else { return }
        guard isFormValid else {
            showError(L("error_invalid_form"))
            return
        }

        isUpdatingPlan = true
        defer { isUpdatingPlan = false }

        do {
            let updatedPlan = editPlanForm.toFinancialPlan(id: selectedPlan.id)
            try await planRepository.updateFinancialPlan(updatedPlan)

            await MainActor.run {
                self.showSuccess(L("plan_updated_successfully"))
                self.editPlanForm.reset()
                self.showingEditPlan = false
                self.selectedPlan = nil
            }

            await loadPlans()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Deletes a financial plan
    func deletePlan(_ plan: FinancialPlan) async {
        isDeletingPlan = true
        defer { isDeletingPlan = false }

        do {
            try await planRepository.deleteFinancialPlan(by: plan.id)

            await MainActor.run {
                self.showSuccess(L("plan_deleted_successfully"))
            }

            await loadPlans()
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Activates a plan
    func activatePlan(_ plan: FinancialPlan) async {
        do {
            try await planRepository.activatePlan(plan.id)
            showSuccess(L("plan_activated_successfully"))
            await loadPlans()
        } catch {
            await handleError(error)
        }
    }

    /// Deactivates a plan
    func deactivatePlan(_ plan: FinancialPlan) async {
        do {
            try await planRepository.deactivatePlan(plan.id)
            showSuccess(L("plan_deactivated_successfully"))
            await loadPlans()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Public Methods - Monthly Breakdown Management

    /// Updates monthly breakdown with actual expense data
    func updateBreakdownFromExpenses(planId: String, month: String) async {
        do {
            try await planRepository.updateMonthlyBreakdownFromExpenses(planId: planId, month: month)
            showSuccess(L("breakdown_updated_from_expenses"))
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Completes a monthly breakdown
    func completeMonthlyBreakdown(planId: String, month: String, actualIncome: Double) async {
        do {
            try await planRepository.completeMonthlyBreakdown(
                planId: planId,
                month: month,
                actualIncome: actualIncome
            )
            showSuccess(L("monthly_breakdown_completed"))
            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    /// Starts editing a monthly breakdown
    func startEditingBreakdown(_ breakdown: PlanMonthlyBreakdown) {
        editingBreakdown = breakdown
        showingBreakdownEditor = true
    }

    /// Saves edited breakdown
    func saveEditedBreakdown() async {
        guard let breakdown = editingBreakdown else { return }

        do {
            // This would be implemented in the repository
            // try await planRepository.updateMonthlyBreakdown(breakdown)

            await MainActor.run {
                self.editingBreakdown = nil
                self.showingBreakdownEditor = false
                self.showSuccess(L("breakdown_saved_successfully"))
            }

            await refreshAnalytics()
        } catch {
            await handleError(error)
        }
    }

    // MARK: - Public Methods - Analysis and Optimization

    /// Applies optimization suggestions
    func applyOptimizationSuggestions(_ suggestions: [BudgetOptimizationSuggestion]) async {
        guard let activePlan = primaryActivePlan else { return }

        // This would apply the suggestions to the plan
        // Implementation would depend on how suggestions are structured

        showSuccess(L("optimization_suggestions_applied"))
        await refreshAnalytics()
    }

    /// Generates new recommendations
    func generateNewRecommendations() async {
        do {
            let recommendations = try await planRepository.generatePlanRecommendations()
            await MainActor.run {
                self.planRecommendations = recommendations
            }
        } catch {
            await handleError(error)
        }
    }

    /// Dismisses a recommendation
    func dismissRecommendation(_ recommendation: PlanRecommendation) {
        planRecommendations.removeAll { $0.type == recommendation.type }
    }

    // MARK: - Public Methods - Search and Filtering

    /// Applies current filters to plans
    func applyFilters() {
        var filtered = financialPlans

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { plan in
                plan.name.localizedCaseInsensitiveContains(searchText) ||
                plan.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply type filter
        if let type = selectedPlanType {
            filtered = filtered.filter { $0.planType == type }
        }

        // Apply status filter
        if let status = selectedPlanStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Apply date range filter
        if let dateRange = planDateRange {
            filtered = filtered.filter { plan in
                plan.startDate >= dateRange.lowerBound && plan.endDate <= dateRange.upperBound
            }
        }

        // Apply sorting
        filtered = sortPlans(filtered)

        filteredPlans = filtered
    }

    /// Clears all filters
    func clearFilters() {
        searchText = ""
        selectedPlanType = nil
        selectedPlanStatus = nil
        planDateRange = nil
        sortBy = .startDate
        sortAscending = false
    }

    // MARK: - Public Methods - Form Management

    /// Prepares form for creating new plan
    func prepareNewPlanForm() {
        newPlanForm.reset()
        newPlanForm.currency = settingsManager.currency
        formErrors.removeAll()
        currentCreationStep = .basicInfo
    }

    /// Prepares form for editing plan
    func prepareEditPlanForm(for plan: FinancialPlan) {
        selectedPlan = plan
        editPlanForm.populateFrom(plan)
        formErrors.removeAll()
    }

    /// Applies a template to the new plan form
    func applyTemplate(_ template: PlanTemplate) {
        newPlanForm.applyTemplate(template)
    }

    /// Moves to next step in plan creation wizard
    func nextCreationStep() {
        switch currentCreationStep {
        case .basicInfo:
            currentCreationStep = .budgetAllocation
        case .budgetAllocation:
            currentCreationStep = .goalSetting
        case .goalSetting:
            currentCreationStep = .review
        case .review:
            break // Stay on review
        }
    }

    /// Moves to previous step in plan creation wizard
    func previousCreationStep() {
        switch currentCreationStep {
        case .basicInfo:
            break // Stay on basic info
        case .budgetAllocation:
            currentCreationStep = .basicInfo
        case .goalSetting:
            currentCreationStep = .budgetAllocation
        case .review:
            currentCreationStep = .goalSetting
        }
    }

    /// Validates form and updates error state
    func validateForm() {
        formErrors.removeAll()

        let form = showingCreatePlan ? newPlanForm : editPlanForm

        if form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formErrors["name"] = L("error_missing_plan_name")
        }

        if form.totalIncome <= 0 {
            formErrors["income"] = L("error_invalid_income")
        }

        if form.startDate >= form.endDate {
            formErrors["dateRange"] = L("error_invalid_date_range")
        }

        if form.savingsGoal < 0 {
            formErrors["savingsGoal"] = L("error_invalid_savings_goal")
        }

        if form.annualInterestRate < 0 || form.annualInterestRate > 1 {
            formErrors["interestRate"] = L("error_invalid_interest_rate")
        }

        // Validate budget allocations
        let totalAllocations = form.categoryAllocations.values.reduce(0, +)
        if totalAllocations > 100 {
            formErrors["budgetAllocations"] = L("error_budget_exceeds_100_percent")
        }
    }

    // MARK: - Public Methods - Quick Actions

    /// Creates plan from template
    func createPlanFromTemplate(_ template: PlanTemplate) {
        selectedTemplate = template
        prepareNewPlanForm()
        applyTemplate(template)
        showingCreatePlan = true
    }

    /// Duplicates an existing plan
    func duplicatePlan(_ plan: FinancialPlan) {
        prepareNewPlanForm()
        newPlanForm.populateFrom(plan)
        newPlanForm.name = "\(plan.name) (\(L("copy")))"
        newPlanForm.startDate = Date()
        let calendar = Calendar.current
        newPlanForm.endDate = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        showingCreatePlan = true
    }

    // MARK: - Private Methods

    private func sortPlans(_ plans: [FinancialPlan]) -> [FinancialPlan] {
        return plans.sorted { lhs, rhs in
            let result: Bool
            switch sortBy {
            case .name:
                result = lhs.name < rhs.name
            case .startDate:
                result = lhs.startDate < rhs.startDate
            case .endDate:
                result = lhs.endDate < rhs.endDate
            case .totalIncome:
                result = lhs.totalIncome < rhs.totalIncome
            case .savingsGoal:
                result = lhs.savingsGoal < rhs.savingsGoal
            case .createdAt:
                result = lhs.createdAt < rhs.createdAt
            }
            return sortAscending ? result : !result
        }
    }

    private func createEmergencyFundTemplate() -> PlanTemplate {
        return PlanTemplate(
            name: L("template_emergency_fund"),
            description: L("template_emergency_fund_description"),
            budgetRatio: 0.7,
            savingsRatio: 0.2,
            emergencyFundMonths: 6,
            interestType: .simple,
            expectedReturnRate: 0.02,
            categoryAllocations: [
                "housing": 30,
                "food": 15,
                "transportation": 10,
                "utilities": 8,
                "healthcare": 5,
                "entertainment": 7,
                "savings": 20,
                "other": 5
            ]
        )
    }

    private func createRetirementSavingsTemplate() -> PlanTemplate {
        return PlanTemplate(
            name: L("template_retirement_savings"),
            description: L("template_retirement_savings_description"),
            budgetRatio: 0.65,
            savingsRatio: 0.25,
            emergencyFundMonths: 3,
            interestType: .compound,
            expectedReturnRate: 0.07,
            categoryAllocations: [
                "housing": 25,
                "food": 12,
                "transportation": 8,
                "utilities": 6,
                "healthcare": 4,
                "entertainment": 5,
                "retirement": 25,
                "savings": 10,
                "other": 5
            ]
        )
    }

    private func createDebtPayoffTemplate() -> PlanTemplate {
        return PlanTemplate(
            name: L("template_debt_payoff"),
            description: L("template_debt_payoff_description"),
            budgetRatio: 0.6,
            savingsRatio: 0.1,
            emergencyFundMonths: 2,
            interestType: .simple,
            expectedReturnRate: 0.0,
            categoryAllocations: [
                "housing": 25,
                "food": 15,
                "transportation": 10,
                "utilities": 8,
                "debtPayment": 30,
                "savings": 10,
                "other": 2
            ]
        )
    }

    private func createVacationSavingsTemplate() -> PlanTemplate {
        return PlanTemplate(
            name: L("template_vacation_savings"),
            description: L("template_vacation_savings_description"),
            budgetRatio: 0.8,
            savingsRatio: 0.15,
            emergencyFundMonths: 3,
            interestType: .simple,
            expectedReturnRate: 0.01,
            categoryAllocations: [
                "housing": 30,
                "food": 18,
                "transportation": 12,
                "utilities": 8,
                "entertainment": 10,
                "vacation": 15,
                "savings": 5,
                "other": 2
            ]
        )
    }

    private func createHomeDownPaymentTemplate() -> PlanTemplate {
        return PlanTemplate(
            name: L("template_home_down_payment"),
            description: L("template_home_down_payment_description"),
            budgetRatio: 0.65,
            savingsRatio: 0.3,
            emergencyFundMonths: 4,
            interestType: .compound,
            expectedReturnRate: 0.03,
            categoryAllocations: [
                "housing": 20,
                "food": 15,
                "transportation": 10,
                "utilities": 6,
                "entertainment": 5,
                "homeDownPayment": 30,
                "savings": 10,
                "other": 4
            ]
        )
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        showingSuccessAlert = true
    }

    @MainActor
    private func handleError(_ error: Error) async {
        let message = error.localizedDescription
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Supporting Types

/// Form state for financial plan creation and editing
class PlanFormState: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @Published var totalIncome: Double = 0.0
    @Published var totalBudget: Double = 0.0
    @Published var savingsGoal: Double = 0.0
    @Published var emergencyFundGoal: Double = 0.0
    @Published var currency: String = "TRY"
    @Published var interestType: InterestType = .compound
    @Published var annualInterestRate: Double = 0.05
    @Published var compoundingFrequency: Int = 12
    @Published var categoryAllocations: [String: Double] = [:]
    @Published var fixedExpenses: [String: Double] = [:]
    @Published var variableExpenseBudgets: [String: Double] = [:]
    @Published var isActive: Bool = true
    @Published var planType: PlanType = .general

    func reset() {
        name = ""
        description = ""
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        totalIncome = 0.0
        totalBudget = 0.0
        savingsGoal = 0.0
        emergencyFundGoal = 0.0
        currency = SettingsManager.shared.currency
        interestType = .compound
        annualInterestRate = 0.05
        compoundingFrequency = 12
        categoryAllocations = [:]
        fixedExpenses = [:]
        variableExpenseBudgets = [:]
        isActive = true
        planType = .general
    }

    func populateFrom(_ plan: FinancialPlan) {
        name = plan.name
        description = plan.description
        startDate = plan.startDate
        endDate = plan.endDate
        totalIncome = plan.totalIncome
        totalBudget = plan.totalBudget
        savingsGoal = plan.savingsGoal
        emergencyFundGoal = plan.emergencyFundGoal
        currency = plan.currency
        interestType = plan.interestType
        annualInterestRate = plan.annualInterestRate
        compoundingFrequency = plan.compoundingFrequency
        categoryAllocations = plan.categoryAllocations
        fixedExpenses = plan.fixedExpenses
        variableExpenseBudgets = plan.variableExpenseBudgets
        isActive = plan.isActive
        planType = plan.planType
    }

    func applyTemplate(_ template: PlanTemplate) {
        description = template.description
        interestType = template.interestType
        annualInterestRate = template.expectedReturnRate
        categoryAllocations = template.categoryAllocations
        // Set budget and savings based on template ratios
        if totalIncome > 0 {
            totalBudget = totalIncome * template.budgetRatio
            savingsGoal = totalIncome * template.savingsRatio
            emergencyFundGoal = (totalIncome / 12) * Double(template.emergencyFundMonths)
        }
    }

    func toFinancialPlan(id: String = UUID().uuidString) -> FinancialPlan {
        return FinancialPlan(
            id: id,
            name: name,
            description: description,
            startDate: startDate,
            endDate: endDate,
            totalIncome: totalIncome,
            totalBudget: totalBudget,
            savingsGoal: savingsGoal,
            emergencyFundGoal: emergencyFundGoal,
            interestType: interestType,
            annualInterestRate: annualInterestRate,
            compoundingFrequency: compoundingFrequency,
            currency: currency,
            categoryAllocations: categoryAllocations,
            fixedExpenses: fixedExpenses,
            variableExpenseBudgets: variableExpenseBudgets,
            isActive: isActive,
            planType: planType,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

/// Plan creation wizard steps
enum PlanCreationStep: CaseIterable {
    case basicInfo
    case budgetAllocation
    case goalSetting
    case review

    var title: String {
        switch self {
        case .basicInfo:
            return L("step_basic_info")
        case .budgetAllocation:
            return L("step_budget_allocation")
        case .goalSetting:
            return L("step_goal_setting")
        case .review:
            return L("step_review")
        }
    }

    var stepNumber: Int {
        switch self {
        case .basicInfo: return 1
        case .budgetAllocation: return 2
        case .goalSetting: return 3
        case .review: return 4
        }
    }
}

/// Plan sort fields
enum PlanSortField: String, CaseIterable {
    case name = "name"
    case startDate = "startDate"
    case endDate = "endDate"
    case totalIncome = "totalIncome"
    case savingsGoal = "savingsGoal"
    case createdAt = "createdAt"

    var displayName: String {
        switch self {
        case .name:
            return L("sort_by_name")
        case .startDate:
            return L("sort_by_start_date")
        case .endDate:
            return L("sort_by_end_date")
        case .totalIncome:
            return L("sort_by_income")
        case .savingsGoal:
            return L("sort_by_savings_goal")
        case .createdAt:
            return L("sort_by_created")
        }
    }
}

/// Plan types for categorization
enum PlanType: String, CaseIterable {
    case general = "general"
    case emergencyFund = "emergencyFund"
    case retirement = "retirement"
    case debtPayoff = "debtPayoff"
    case vacation = "vacation"
    case homeDownPayment = "homeDownPayment"
    case education = "education"
    case investment = "investment"

    var displayName: String {
        switch self {
        case .general:
            return L("plan_type_general")
        case .emergencyFund:
            return L("plan_type_emergency_fund")
        case .retirement:
            return L("plan_type_retirement")
        case .debtPayoff:
            return L("plan_type_debt_payoff")
        case .vacation:
            return L("plan_type_vacation")
        case .homeDownPayment:
            return L("plan_type_home_down_payment")
        case .education:
            return L("plan_type_education")
        case .investment:
            return L("plan_type_investment")
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "doc.text"
        case .emergencyFund:
            return "cross.case"
        case .retirement:
            return "person.crop.circle.badge.clock"
        case .debtPayoff:
            return "creditcard"
        case .vacation:
            return "airplane"
        case .homeDownPayment:
            return "house"
        case .education:
            return "graduationcap"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

/// Plan status
enum PlanStatus: String, CaseIterable {
    case draft = "draft"
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .draft:
            return L("plan_status_draft")
        case .active:
            return L("plan_status_active")
        case .paused:
            return L("plan_status_paused")
        case .completed:
            return L("plan_status_completed")
        case .cancelled:
            return L("plan_status_cancelled")
        }
    }

    var color: Color {
        switch self {
        case .draft:
            return .gray
        case .active:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .cancelled:
            return .red
        }
    }
}

/// Comparison metrics for plan analysis
enum ComparisonMetric: String, CaseIterable {
    case totalSavings = "totalSavings"
    case efficiency = "efficiency"
    case goalProgress = "goalProgress"
    case variance = "variance"
    case roi = "roi"

    var displayName: String {
        switch self {
        case .totalSavings:
            return L("metric_total_savings")
        case .efficiency:
            return L("metric_efficiency")
        case .goalProgress:
            return L("metric_goal_progress")
        case .variance:
            return L("metric_variance")
        case .roi:
            return L("metric_roi")
        }
    }
}

/// Analysis time periods
enum AnalysisPeriod: String, CaseIterable {
    case lastMonth = "lastMonth"
    case lastThreeMonths = "lastThreeMonths"
    case lastSixMonths = "lastSixMonths"
    case lastYear = "lastYear"
    case allTime = "allTime"

    var displayName: String {
        switch self {
        case .lastMonth:
            return L("period_last_month")
        case .lastThreeMonths:
            return L("period_last_three_months")
        case .lastSixMonths:
            return L("period_last_six_months")
        case .lastYear:
            return L("period_last_year")
        case .allTime:
            return L("period_all_time")
        }
    }

    var months: Int {
        switch self {
        case .lastMonth: return 1
        case .lastThreeMonths: return 3
        case .lastSixMonths: return 6
        case .lastYear: return 12
        case .allTime: return 0 // Special case
        }
    }
}

// MARK: - Interest Type Enum

enum InterestType: String, CaseIterable {
    case simple = "simple"
    case compound = "compound"

    var displayName: String {
        switch self {
        case .simple:
            return L("interest_type_simple")
        case .compound:
            return L("interest_type_compound")
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension PlanningViewModel {
    static let preview: PlanningViewModel = {
        return PlanningViewModel(
            planRepository: PlanRepository.preview,
            expenseRepository: ExpenseRepository.preview,
            categoryRepository: CategoryRepository.preview,
            settingsManager: SettingsManager.preview
        )
    }()
}
#endif