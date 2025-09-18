//
//  PlanningView.swift
//  ExpenseTracker
//
//  Financial planning interface screen with plan management and projections
//

import SwiftUI

struct PlanningView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var planningViewModel: PlanningViewModel
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - State

    @State private var showingCreatePlan = false
    @State private var showingPlanDetails = false
    @State private var selectedPlan: FinancialPlan?
    @State private var showingFilters = false
    @State private var planViewMode: PlanViewMode = .grid

    // Search and filter state
    @State private var searchText = ""
    @State private var selectedPlanType: PlanType?
    @State private var selectedPlanStatus: PlanStatus?

    // Animation state
    @State private var isLoaded = false

    // Plan view modes
    enum PlanViewMode: String, CaseIterable {
        case grid = "grid"
        case list = "list"

        var iconName: String {
            switch self {
            case .grid:
                return "grid"
            case .list:
                return "list.bullet"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.themedBackground(appTheme.colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header Section
                    headerSection

                    // MARK: - Search and Filter Section
                    searchAndFilterSection

                    // MARK: - Quick Stats Section
                    quickStatsSection

                    // MARK: - Plans Content
                    plansContentSection
                }

                // MARK: - Floating Action Button
                floatingActionButton
            }
            .navigationBarHidden(true)
            .themedBackground()
            .onAppear {
                loadInitialData()
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanDialog(
                    onPlanCreated: { plan in
                        Task {
                            await planningViewModel.createPlan(plan)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailBottomSheet(
                    plan: plan,
                    onUpdate: { updatedPlan in
                        Task {
                            await planningViewModel.updatePlan(updatedPlan)
                        }
                    },
                    onDelete: {
                        Task {
                            await planningViewModel.deletePlan(plan)
                        }
                        selectedPlan = nil
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingFilters) {
                PlanFiltersView(
                    selectedPlanType: $selectedPlanType,
                    selectedPlanStatus: $selectedPlanStatus
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert(L("error"), isPresented: $planningViewModel.showingErrorAlert) {
                Button(L("ok")) {
                    planningViewModel.showingErrorAlert = false
                }
            } message: {
                Text(planningViewModel.errorMessage ?? L("unknown_error"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Top header with title and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("financial_planning"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .themedTextColor()

                    Text(L("plan_your_financial_future"))
                        .font(.subheadline)
                        .themedSecondaryTextColor()
                }

                Spacer()

                HStack(spacing: 12) {
                    // View mode toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            planViewMode = planViewMode == .grid ? .list : .grid
                        }
                    }) {
                        Image(systemName: planViewMode.iconName)
                            .font(.title3)
                            .themedTextColor()
                            .frame(width: 44, height: 44)
                            .themedCardBackground()
                            .cornerRadius(12)
                    }

                    // Filters button
                    Button(action: { showingFilters = true }) {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundColor(hasActiveFilters ? .orange : Color.themedText(appTheme.colorScheme))
                                .frame(width: 44, height: 44)
                                .themedCardBackground()
                                .cornerRadius(12)

                            if hasActiveFilters {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12, y: -12)
                            }
                        }
                    }
                }
            }

            // Plan type quick filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PlanTypeFilterChip(
                        planType: nil,
                        isSelected: selectedPlanType == nil,
                        title: L("all_plans")
                    ) {
                        selectedPlanType = nil
                        applyFilters()
                    }

                    ForEach(PlanType.allCases, id: \.rawValue) { planType in
                        PlanTypeFilterChip(
                            planType: planType,
                            isSelected: selectedPlanType == planType,
                            title: planType.displayName
                        ) {
                            selectedPlanType = selectedPlanType == planType ? nil : planType
                            applyFilters()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(L("search_plans"), text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .themedTextColor()
                    .onChange(of: searchText) { newValue in
                        planningViewModel.searchText = newValue
                    }

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        planningViewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .themedInputBackground()
            .cornerRadius(12)

            // Active filters display
            if hasActiveFilters {
                activeFiltersDisplay
            }
        }
        .padding(.horizontal, 20)
    }

    private var activeFiltersDisplay: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let planType = selectedPlanType {
                    FilterChip(
                        title: planType.displayName,
                        onRemove: { selectedPlanType = nil; applyFilters() }
                    )
                }

                if let planStatus = selectedPlanStatus {
                    FilterChip(
                        title: planStatus.displayName,
                        onRemove: { selectedPlanStatus = nil; applyFilters() }
                    )
                }

                Button(L("clear_all")) {
                    clearAllFilters()
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L("planning_overview"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Spacer()

                if planningViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(0.8)
                }
            }

            HStack(spacing: 12) {
                // Active plans
                QuickStatCard(
                    title: L("active_plans"),
                    value: "\(planningViewModel.activePlans.count)",
                    subtitle: L("currently_running"),
                    icon: "target",
                    color: .green
                )

                // Total planned amount
                QuickStatCard(
                    title: L("planned_savings"),
                    value: formatCurrency(totalPlannedAmount),
                    subtitle: L("target_amount"),
                    icon: "banknote",
                    color: .blue
                )

                // Achievement rate
                QuickStatCard(
                    title: L("achievement_rate"),
                    value: "\(Int(averageAchievementRate))%",
                    subtitle: L("average_progress"),
                    icon: "chart.line.uptrend.xyaxis",
                    color: achievementRateColor
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Plans Content Section

    private var plansContentSection: some View {
        Group {
            if planningViewModel.isLoading && planningViewModel.financialPlans.isEmpty {
                loadingView
            } else if planningViewModel.filteredPlans.isEmpty {
                emptyStateView
            } else {
                plansListView
            }
        }
        .opacity(isLoaded ? 1 : 0)
        .offset(y: isLoaded ? 0 : 20)
        .animation(.easeOut(duration: 0.6), value: isLoaded)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                .scaleEffect(1.2)

            Text(L("loading_plans"))
                .font(.subheadline)
                .themedSecondaryTextColor()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "target")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))

            VStack(spacing: 8) {
                Text(hasActiveFilters ? L("no_plans_match_filters") : L("no_plans_yet"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .themedTextColor()

                Text(hasActiveFilters ? L("try_adjusting_filters") : L("create_first_plan_message"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                if hasActiveFilters {
                    Button(L("clear_filters")) {
                        clearAllFilters()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button(L("create_plan")) {
                    showingCreatePlan = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedBackground()
    }

    // MARK: - Plans List View

    private var plansListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if planViewMode == .grid {
                    plansGridView
                } else {
                    plansListRows
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Account for floating button
        }
    }

    private var plansGridView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(planningViewModel.filteredPlans) { plan in
                PlanCard(
                    plan: plan,
                    compactMode: true,
                    onTap: {
                        selectedPlan = plan
                    },
                    onUpdate: { updatedPlan in
                        Task {
                            await planningViewModel.updatePlan(updatedPlan)
                        }
                    }
                )
            }
        }
    }

    private var plansListRows: some View {
        ForEach(planningViewModel.filteredPlans) { plan in
            PlanCard(
                plan: plan,
                compactMode: false,
                onTap: {
                    selectedPlan = plan
                },
                onUpdate: { updatedPlan in
                    Task {
                        await planningViewModel.updatePlan(updatedPlan)
                    }
                }
            )
        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button(action: {
                    showingCreatePlan = true
                    settingsManager.triggerHapticFeedback(.medium)
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(.orange.gradient)
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 34) // Account for safe area
        }
    }

    // MARK: - Helper Methods

    private func loadInitialData() {
        guard !isLoaded else { return }

        Task {
            await planningViewModel.loadPlans()
            await planningViewModel.refreshAnalytics()

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    isLoaded = true
                }
            }
        }
    }

    private func refreshData() async {
        await planningViewModel.loadPlans()
        await planningViewModel.refreshAnalytics()
    }

    private func applyFilters() {
        planningViewModel.selectedPlanType = selectedPlanType
        planningViewModel.selectedPlanStatus = selectedPlanStatus
    }

    private func clearAllFilters() {
        selectedPlanType = nil
        selectedPlanStatus = nil
        searchText = ""
        planningViewModel.searchText = ""
        applyFilters()
    }

    private var hasActiveFilters: Bool {
        return selectedPlanType != nil || selectedPlanStatus != nil || !searchText.isEmpty
    }

    private var totalPlannedAmount: Double {
        return planningViewModel.activePlans.reduce(0) { $0 + $1.targetAmount }
    }

    private var averageAchievementRate: Double {
        let activePlans = planningViewModel.activePlans
        guard !activePlans.isEmpty else { return 0 }

        let totalProgress = activePlans.reduce(0) { total, plan in
            return total + plan.calculateProgress()
        }

        return (totalProgress / Double(activePlans.count)) * 100
    }

    private var achievementRateColor: Color {
        let rate = averageAchievementRate
        if rate >= 80 {
            return .green
        } else if rate >= 60 {
            return .blue
        } else if rate >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        return settingsManager.formatCurrency(amount)
    }
}

// MARK: - Supporting Views

struct PlanTypeFilterChip: View {
    let planType: PlanType?
    let isSelected: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .orange)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .orange : .orange.opacity(0.2))
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.orange)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.1))
        .cornerRadius(16)
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .themedTextColor()

                Text(subtitle)
                    .font(.caption2)
                    .themedSecondaryTextColor()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCardBackground()
        .cornerRadius(12)
    }
}

// MARK: - Filter View

struct PlanFiltersView: View {
    @Binding var selectedPlanType: PlanType?
    @Binding var selectedPlanStatus: PlanStatus?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text(L("plan_filters"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                // Plan type filter
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("plan_type"))
                        .font(.headline)
                        .themedTextColor()

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(PlanType.allCases, id: \.rawValue) { planType in
                            Button(action: {
                                selectedPlanType = selectedPlanType == planType ? nil : planType
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: planType.iconName)
                                        .font(.title2)
                                        .foregroundColor(selectedPlanType == planType ? .white : .orange)

                                    Text(planType.displayName)
                                        .font(.caption)
                                        .foregroundColor(selectedPlanType == planType ? .white : .orange)
                                }
                                .frame(height: 80)
                                .frame(maxWidth: .infinity)
                                .background(selectedPlanType == planType ? .orange : .orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // Plan status filter
                VStack(alignment: .leading, spacing: 12) {
                    Text(L("plan_status"))
                        .font(.headline)
                        .themedTextColor()

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(PlanStatus.allCases, id: \.rawValue) { status in
                            Button(action: {
                                selectedPlanStatus = selectedPlanStatus == status ? nil : status
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: status.iconName)
                                        .font(.title2)
                                        .foregroundColor(selectedPlanStatus == status ? .white : status.color)

                                    Text(status.displayName)
                                        .font(.caption)
                                        .foregroundColor(selectedPlanStatus == status ? .white : status.color)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(selectedPlanStatus == status ? status.color : status.color.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                Spacer()

                // Apply button
                Button(L("apply_filters")) {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .themedBackground()
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange.gradient)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Extensions

extension FinancialPlan: Identifiable {}

// MARK: - Preview

#if DEBUG
struct PlanningView_Previews: PreviewProvider {
    static var previews: some View {
        PlanningView()
            .environmentObject(PlanningViewModel.preview)
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .preferredColorScheme(.dark)
    }
}
#endif