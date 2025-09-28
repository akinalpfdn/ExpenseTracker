//
//  PlanningView.swift
//  ExpenseTracker
//
//  Created by migration from Android PlanningScreen.kt
//

import SwiftUI

struct PlanningView: View {
    @EnvironmentObject var planningViewModel: PlanningViewModel

    let isDarkTheme: Bool
    let defaultCurrency: String

    @State private var showCreatePlanDialog = false
    @State private var selectedPlanForDetail: String?
    @State private var planToDelete: String?

    var body: some View {
        ZStack {
            ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 16)

                // Header
                headerSection

                Spacer().frame(height: 24)

                // Content
                contentSection
            }

            // Floating Action Button
            floatingActionButton
        }
        .sheet(isPresented: $showCreatePlanDialog) {
            createPlanSheet
        }
        .sheet(item: Binding<PlanDetailSheetItem?>(
            get: {
                guard let planId = selectedPlanForDetail else { return nil }
                return PlanDetailSheetItem(planId: planId)
            },
            set: { item in
                selectedPlanForDetail = item?.planId
            }
        )) { item in
            planDetailSheet(planId: item.planId)
        }
        .alert("delete_plan".localized, isPresented: Binding<Bool>(
            get: { planToDelete != nil },
            set: { if !$0 { planToDelete = nil } }
        )) {
            deleteConfirmationAlert
        }
        .onReceive(planningViewModel.$error) { error in
            if let error = error {
                // Handle error display - could use a toast or alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    planningViewModel.clearError()
                }
            }
        }
    }
}

// MARK: - View Components
extension PlanningView {
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("financial_planning".localized)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Text("planning_description".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var contentSection: some View {
        if planningViewModel.isLoading {
            loadingView
        } else if planningViewModel.plansWithBreakdowns.isEmpty {
            emptyStateView
        } else {
            plansListView
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryOrange))
                .scaleEffect(1.5)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("📊")
                .font(.system(size: 64))

            Text("no_plans_yet".localized)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Text("create_first_plan".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var plansListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(planningViewModel.plansWithBreakdowns.enumerated()), id: \.element.plan.id) { index, planWithBreakdowns in
                    AnimatedPlanCard(
                        index: index,
                        planWithBreakdowns: planWithBreakdowns,
                        onCardClick: {
                            planningViewModel.selectPlan(planId: planWithBreakdowns.plan.id)
                            selectedPlanForDetail = planWithBreakdowns.plan.id
                        },
                        onDeleteClick: {
                            planToDelete = planWithBreakdowns.plan.id
                        },
                        isDarkTheme: isDarkTheme,
                        defaultCurrency: defaultCurrency
                    )
                    .environmentObject(planningViewModel)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                Button(action: { showCreatePlanDialog = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [AppColors.buttonGradientStart, AppColors.buttonGradientEnd],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "plus")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Sheet Views
    @ViewBuilder
    private var createPlanSheet: some View {
        CreatePlanDialog(
            onDismiss: { showCreatePlanDialog = false },
            onCreatePlan: { name, duration, income, expenses, useAppData, inflationApplied, inflationRate, interestApplied, interestRate, interestType in
                planningViewModel.createPlan(
                    name: name,
                    startDate: Date(),
                    durationInMonths: duration,
                    monthlyIncome: income,
                    manualMonthlyExpenses: expenses,
                    useAppExpenseData: useAppData,
                    isInflationApplied: inflationApplied,
                    inflationRate: inflationRate,
                    isInterestApplied: interestApplied,
                    interestRate: interestRate,
                    interestType: interestType,
                    defaultCurrency: defaultCurrency
                )
                showCreatePlanDialog = false
            },
            isDarkTheme: isDarkTheme,
            defaultCurrency: defaultCurrency
        )
    }

    @ViewBuilder
    private func planDetailSheet(planId: String) -> some View {
        if let selectedPlan = planningViewModel.selectedPlan {
            PlanDetailBottomSheet(
                planWithBreakdowns: selectedPlan,
                onUpdateBreakdown: { updatedBreakdown in
                    planningViewModel.updatePlanBreakdown(updatedBreakdown)
                },
                onUpdateExpenseData: {
                    planningViewModel.updateExpenseData(planId: selectedPlan.plan.id)
                },
                isDarkTheme: isDarkTheme,
                defaultCurrency: defaultCurrency
            )
            .environmentObject(planningViewModel)
        }
    }

    @ViewBuilder
    private var deleteConfirmationAlert: some View {
        if let planId = planToDelete {
            let planName = planningViewModel.plansWithBreakdowns.first { $0.plan.id == planId }?.plan.name ?? "Plan"

            Button("delete".localized, role: .destructive) {
                planningViewModel.deletePlan(planId: planId)
                planToDelete = nil
            }

            Button("cancel".localized, role: .cancel) {
                planToDelete = nil
            }
        }
    }
}

// MARK: - AnimatedPlanCard
struct AnimatedPlanCard: View {
    @EnvironmentObject var planningViewModel: PlanningViewModel

    let index: Int
    let planWithBreakdowns: PlanWithBreakdowns
    let onCardClick: () -> Void
    let onDeleteClick: () -> Void
    let isDarkTheme: Bool
    let defaultCurrency: String

    @State private var isVisible = false

    var body: some View {
        PlanCard(
            planWithBreakdowns: planWithBreakdowns,
            onCardClick: onCardClick,
            onDeleteClick: onDeleteClick,
            isDarkTheme: isDarkTheme,
            defaultCurrency: defaultCurrency
        )
        .environmentObject(planningViewModel)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 100)
        .animation(
            .easeOut(duration: 0.6)
            .delay(Double(index) * 0.1),
            value: isVisible
        )
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}

// MARK: - Helper Types
struct PlanDetailSheetItem: Identifiable {
    let id = UUID()
    let planId: String
}

// MARK: - Preview
struct PlanningView_Previews: PreviewProvider {
    static var previews: some View {
        let planningViewModel = PlanningViewModel()

        PlanningView(
            isDarkTheme: true,
            defaultCurrency: "₺"
        )
        .environmentObject(planningViewModel)
    }
}
