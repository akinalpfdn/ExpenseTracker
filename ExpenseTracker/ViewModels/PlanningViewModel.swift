//
//  PlanningViewModel.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanningViewModel.kt
//

import Foundation
import Combine

class PlanningViewModel: ObservableObject {
    private let planRepository: PlanRepository

    // MARK: - Published Properties

    @Published var plans: [FinancialPlan] = []
    @Published var plansWithBreakdowns: [PlanWithBreakdowns] = []
    @Published var selectedPlan: PlanWithBreakdowns?
    @Published var currentPosition: PlanCurrentPosition?
    @Published var isLoading = false
    @Published var error: String?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(planRepository: PlanRepository = PlanRepository()) {
        self.planRepository = planRepository
        loadPlans()
    }

    // MARK: - Data Loading

    private func loadPlans() {
        Task {
            await loadPlansData()
            await loadPlansWithBreakdowns()
        }
    }

    @MainActor
    private func loadPlansData() async {
        do {
            plans = try await planRepository.getAllPlans()
        } catch {
            self.error = "Plans yüklenirken hata oluştu: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func loadPlansWithBreakdowns() async {
        do {
            plansWithBreakdowns = try await planRepository.getAllPlansWithBreakdowns()
        } catch {
            self.error = "Plan detayları yüklenirken hata oluştu: \(error.localizedDescription)"
        }
    }

    // MARK: - Plan Selection

    func selectPlan(planId: String) {
        Task {
            await MainActor.run { isLoading = true }

            do {
                let planWithBreakdowns = try await planRepository.getPlanWithBreakdowns(planId: planId)

                await MainActor.run {
                    selectedPlan = planWithBreakdowns
                }

                // Load current position if plan is active
                if planWithBreakdowns?.plan.isActive() == true {
                    let position = try await planRepository.getCurrentFinancialPosition(planId: planId)
                    await MainActor.run {
                        currentPosition = position
                    }
                }

            } catch {
                await MainActor.run {
                    self.error = "Plan yüklenirken hata oluştu: \(error.localizedDescription)"
                }
            }

            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - Plan Creation

    func createPlan(
        name: String,
        startDate: Date,
        durationInMonths: Int,
        monthlyIncome: Double,
        manualMonthlyExpenses: Double = 0.0,
        useAppExpenseData: Bool = true,
        isInflationApplied: Bool = false,
        inflationRate: Double = 0.0,
        isInterestApplied: Bool = false,
        interestRate: Double = 0.0,
        interestType: InterestType = .compound,
        defaultCurrency: String
    ) {
        Task {
            await MainActor.run { isLoading = true }

            do {
                let validation = PlanningUtils.validatePlanInput(
                    name: name,
                    monthlyIncome: monthlyIncome,
                    durationInMonths: durationInMonths,
                    inflationRate: isInflationApplied ? inflationRate : nil
                )

                if !validation.isValid {
                    await MainActor.run {
                        error = validation.errors.first
                    }
                    return
                }

                let newPlan = FinancialPlan(
                    name: name,
                    startDate: startDate,
                    durationInMonths: durationInMonths,
                    monthlyIncome: monthlyIncome,
                    manualMonthlyExpenses: manualMonthlyExpenses,
                    useAppExpenseData: useAppExpenseData,
                    isInflationApplied: isInflationApplied,
                    inflationRate: inflationRate,
                    isInterestApplied: isInterestApplied,
                    interestRate: interestRate,
                    interestType: interestType,
                    defaultCurrency: defaultCurrency
                )

                try await planRepository.insertPlan(newPlan)

                await MainActor.run {
                    clearError()
                }

                await loadPlansData()
                await loadPlansWithBreakdowns()

            } catch {
                await MainActor.run {
                    self.error = "Plan oluşturulurken hata oluştu: \(error.localizedDescription)"
                }
            }

            await MainActor.run { isLoading = false }
        }
    }

    // MARK: - Plan Management

    func deletePlan(planId: String) {
        Task {
            await MainActor.run { isLoading = true }

            do {
                try await planRepository.deletePlan(planId: planId)

                await MainActor.run {
                    if selectedPlan?.plan.id == planId {
                        selectedPlan = nil
                        currentPosition = nil
                    }
                    clearError()
                }

                await loadPlansData()
                await loadPlansWithBreakdowns()

            } catch {
                await MainActor.run {
                    self.error = "Plan silinirken hata oluştu: \(error.localizedDescription)"
                }
            }

            await MainActor.run { isLoading = false }
        }
    }

    func updateExpenseData(planId: String) {
        Task {
            await MainActor.run { isLoading = true }

            do {
                try await planRepository.updateExpenseData(planId: planId)

                // Refresh selected plan if it's the current one
                if selectedPlan?.plan.id == planId {
                    selectPlan(planId: planId)
                }

                await MainActor.run {
                    clearError()
                }

            } catch {
                await MainActor.run {
                    self.error = "Harcama verileri güncellenirken hata oluştu: \(error.localizedDescription)"
                }
            }

            await MainActor.run { isLoading = false }
        }
    }

    func updatePlanBreakdown(_ updatedBreakdown: PlanMonthlyBreakdown) {
        Task {
            do {
                try await planRepository.updateBreakdown(updatedBreakdown)

                // Recalculate cumulative amounts for all subsequent months
                let planId = updatedBreakdown.planId
                try await planRepository.recalculateCumulativeAmounts(planId: planId)

                // Refresh the selected plan to show updated values
                if selectedPlan?.plan.id == planId {
                    selectPlan(planId: planId)
                }

                await MainActor.run {
                    clearError()
                }

            } catch {
                await MainActor.run {
                    self.error = "Değişiklikler kaydedilirken hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Helper Methods

    func clearSelectedPlan() {
        selectedPlan = nil
        currentPosition = nil
    }

    func clearError() {
        error = nil
    }
}