//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Updated with comprehensive dependency injection setup and Core Data integration
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    // MARK: - Dependencies

    /// Core Data stack - initialized early for dependency injection
    @StateObject private var coreDataStack = CoreDataStack.shared

    /// Settings manager - shared singleton for app-wide settings
    @StateObject private var settingsManager = SettingsManager.shared

    /// App theme manager for theming support
    @StateObject private var appTheme = AppTheme.shared

    /// Localization manager for multi-language support
    @StateObject private var localizationManager = LocalizationManager.shared

    // MARK: - Repository Dependencies

    /// Expense repository for expense operations
    @StateObject private var expenseRepository = ExpenseRepository()

    /// Category repository for category management
    @StateObject private var categoryRepository = CategoryRepository()

    /// Plan repository for financial planning
    @StateObject private var planRepository = PlanRepository()

    // MARK: - View Models

    /// Main expense view model
    @StateObject private var expenseViewModel: ExpenseViewModel

    /// Planning view model
    @StateObject private var planningViewModel: PlanningViewModel

    // MARK: - App State

    /// App lifecycle state
    @Environment(\.scenePhase) private var scenePhase

    /// Custom initializer to set up dependency injection
    init() {
        // Initialize ViewModels with their dependencies
        let expenseVM = ExpenseViewModel(
            expenseRepository: ExpenseRepository(),
            categoryRepository: CategoryRepository(),
            settingsManager: SettingsManager.shared
        )
        _expenseViewModel = StateObject(wrappedValue: expenseVM)

        let planningVM = PlanningViewModel(
            planRepository: PlanRepository(),
            expenseRepository: ExpenseRepository(),
            categoryRepository: CategoryRepository(),
            settingsManager: SettingsManager.shared
        )
        _planningViewModel = StateObject(wrappedValue: planningVM)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if coreDataStack.hasInitialized {
                    MainContentView()
                        .environment(\.managedObjectContext, coreDataStack.viewContext)
                        .environmentObject(coreDataStack)
                        .environmentObject(settingsManager)
                        .environmentObject(appTheme)
                        .environmentObject(localizationManager)
                        .environmentObject(expenseRepository)
                        .environmentObject(categoryRepository)
                        .environmentObject(planRepository)
                        .environmentObject(expenseViewModel)
                        .environmentObject(planningViewModel)
                        .withAppTheme()
                } else {
                    LoadingView()
                        .withAppTheme()
                }
            }
            .onAppear {
                setupApp()
            }
            .onChange(of: scenePhase) { phase in
                handleScenePhaseChange(phase)
            }
        }
    }

    // MARK: - Private Methods

    /// Sets up the app on first launch
    private func setupApp() {
        // Load user preferences
        settingsManager.loadSettings()
        appTheme.loadThemePreference()

        // Configure app appearance based on settings
        configureAppAppearance()

        // Setup notifications if needed
        setupNotifications()
    }

    /// Configures app appearance based on current settings
    private func configureAppAppearance() {
        // Apply theme settings
        if settingsManager.theme != .system {
            appTheme.setTheme(settingsManager.theme == .dark)
        }

        // Configure haptic feedback
        if !settingsManager.hapticFeedbackEnabled {
            // Disable system-wide haptic feedback if needed
        }
    }

    /// Sets up notifications if enabled
    private func setupNotifications() {
        guard settingsManager.notificationsEnabled else { return }

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    // Setup notification categories if needed
                    self.setupNotificationCategories()
                }
            }
        }
    }

    /// Sets up notification categories for different types of notifications
    private func setupNotificationCategories() {
        let limitExceededCategory = UNNotificationCategory(
            identifier: "LIMIT_EXCEEDED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_EXPENSES",
                    title: L("view_expenses"),
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "ADJUST_LIMIT",
                    title: L("adjust_limit"),
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        let recurringExpenseCategory = UNNotificationCategory(
            identifier: "RECURRING_EXPENSE",
            actions: [
                UNNotificationAction(
                    identifier: "CONFIRM_EXPENSE",
                    title: L("confirm"),
                    options: []
                ),
                UNNotificationAction(
                    identifier: "SKIP_EXPENSE",
                    title: L("skip"),
                    options: []
                )
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            limitExceededCategory,
            recurringExpenseCategory
        ])
    }

    /// Handles app lifecycle changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            Task {
                await expenseViewModel.refreshAnalytics()
                await planningViewModel.refreshAnalytics()
            }

        case .inactive:
            // App became inactive
            break

        case .background:
            // App went to background
            saveAppState()

        @unknown default:
            break
        }
    }

    /// Saves app state when going to background
    private func saveAppState() {
        // Save Core Data context if needed
        do {
            try coreDataStack.saveViewContext()
        } catch {
            print("Failed to save app state: \(error)")
        }

        // Save any pending settings
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Loading View

/// Loading view shown while Core Data stack initializes
struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // App logo or icon
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Text(L("expense_tracker"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(L("loading_app"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
