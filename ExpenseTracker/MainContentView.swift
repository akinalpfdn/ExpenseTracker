//
//  MainContentView.swift
//  ExpenseTracker
//
//  Main content view with tab-based navigation
//

import SwiftUI

struct MainContentView: View {
    // MARK: - Environment Objects

    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var planningViewModel: PlanningViewModel

    // MARK: - State

    @State private var selectedTab: TabType = .expenses
    @State private var isFirstLaunch = true

    // MARK: - Tab Types

    enum TabType: String, CaseIterable {
        case expenses = "expenses"
        case analysis = "analysis"
        case planning = "planning"

        var title: String {
            switch self {
            case .expenses:
                return L("tab_expenses")
            case .analysis:
                return L("tab_analysis")
            case .planning:
                return L("tab_planning")
            }
        }

        var icon: String {
            switch self {
            case .expenses:
                return "creditcard"
            case .analysis:
                return "chart.pie"
            case .planning:
                return "target"
            }
        }

        var selectedIcon: String {
            switch self {
            case .expenses:
                return "creditcard.fill"
            case .analysis:
                return "chart.pie.fill"
            case .planning:
                return "target"
            }
        }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // MARK: - Expenses Tab
                ExpensesView()
                    .tabItem {
                        Image(systemName: selectedTab == .expenses ? TabType.expenses.selectedIcon : TabType.expenses.icon)
                        Text(TabType.expenses.title)
                    }
                    .tag(TabType.expenses)

                // MARK: - Analysis Tab
                AnalysisView()
                    .tabItem {
                        Image(systemName: selectedTab == .analysis ? TabType.analysis.selectedIcon : TabType.analysis.icon)
                        Text(TabType.analysis.title)
                    }
                    .tag(TabType.analysis)

                // MARK: - Planning Tab
                PlanningView()
                    .tabItem {
                        Image(systemName: selectedTab == .planning ? TabType.planning.selectedIcon : TabType.planning.icon)
                        Text(TabType.planning.title)
                    }
                    .tag(TabType.planning)
            }
            .accentColor(.orange)
            .themedBackground()
            .onAppear {
                configureTabBarAppearance()
                handleFirstLaunch()
            }
            .onChange(of: selectedTab) { newTab in
                handleTabChange(newTab)

                // Haptic feedback for tab changes
                settingsManager.triggerHapticFeedback(.light)
            }
        }
    }

    // MARK: - Private Methods

    /// Configures the tab bar appearance based on current theme
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        // Configure background
        if appTheme.isDarkMode {
            appearance.backgroundColor = UIColor.black
            appearance.shadowColor = UIColor.gray.withAlphaComponent(0.3)
        } else {
            appearance.backgroundColor = UIColor.white
            appearance.shadowColor = UIColor.gray.withAlphaComponent(0.2)
        }

        // Configure item appearance
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.orange
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.orange
        ]

        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    /// Handles first launch setup
    private func handleFirstLaunch() {
        guard isFirstLaunch else { return }
        isFirstLaunch = false

        // Load initial data for all view models
        Task {
            async let loadExpenses: Void = expenseViewModel.loadExpenses()
            async let loadPlans: Void = planningViewModel.loadPlans()
            async let refreshAnalytics: Void = expenseViewModel.refreshAnalytics()

            // Wait for all operations to complete
            _ = await (loadExpenses, loadPlans, refreshAnalytics)
        }
    }

    /// Handles tab changes and loads relevant data
    private func handleTabChange(_ newTab: TabType) {
        switch newTab {
        case .expenses:
            // Refresh expense data when switching to expenses tab
            Task {
                await expenseViewModel.loadExpenses()
            }

        case .analysis:
            // Refresh analytics when switching to analysis tab
            Task {
                await expenseViewModel.refreshAnalytics()
            }

        case .planning:
            // Refresh planning data when switching to planning tab
            Task {
                await planningViewModel.refreshAnalytics()
            }
        }
    }
}

// MARK: - Tab Content Views Placeholder

/// Temporary placeholder views that will be replaced with actual implementations
extension MainContentView {

    /// Placeholder for when views don't exist yet
    struct PlaceholderView: View {
        let title: String
        let icon: String

        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.orange.opacity(0.7))

                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .themedTextColor()

                Text(L("coming_soon"))
                    .font(.subheadline)
                    .themedSecondaryTextColor()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .themedBackground()
        }
    }
}

// MARK: - Custom Tab Bar Implementation (Alternative)

/// Custom tab bar for more control over appearance and animations
struct CustomTabBar: View {
    @Binding var selectedTab: MainContentView.TabType
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainContentView.TabType.allCases, id: \.rawValue) { tab in
                CustomTabItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                    settingsManager.triggerHapticFeedback(.light)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .themedCardBackground()
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 34) // Account for safe area
    }
}

/// Individual tab item for custom tab bar
struct CustomTabItem: View {
    let tab: MainContentView.TabType
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .orange : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(tab.title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .orange : .gray)
            }
            .frame(height: 44)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(SettingsManager.preview)
            .environmentObject(AppTheme.shared)
            .environmentObject(ExpenseViewModel.preview)
            .environmentObject(PlanningViewModel.preview)
            .preferredColorScheme(.dark)
    }
}
#endif