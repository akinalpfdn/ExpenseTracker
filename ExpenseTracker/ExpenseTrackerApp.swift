//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by migration from Android MainActivity.kt
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var preferencesManager = PreferencesManager()
    @StateObject private var expenseRepository = ExpenseRepository()
    @StateObject private var categoryRepository = CategoryRepository()
    @StateObject private var planRepository = PlanRepository()

    @StateObject private var expenseViewModel: ExpenseViewModel
    @StateObject private var planningViewModel: PlanningViewModel

    init() {
        let prefsManager = PreferencesManager()
        let expenseRepo = ExpenseRepository()
        let categoryRepo = CategoryRepository()
        let planRepo = PlanRepository()

        self._preferencesManager = StateObject(wrappedValue: prefsManager)
        self._expenseRepository = StateObject(wrappedValue: expenseRepo)
        self._categoryRepository = StateObject(wrappedValue: categoryRepo)
        self._planRepository = StateObject(wrappedValue: planRepo)

        self._expenseViewModel = StateObject(wrappedValue: ExpenseViewModel(
            preferencesManager: prefsManager,
            expenseRepository: expenseRepo,
            categoryRepository: categoryRepo
        ))

        self._planningViewModel = StateObject(wrappedValue: PlanningViewModel(
            planRepository: planRepo
        ))
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(preferencesManager)
                .environmentObject(expenseViewModel)
                .environmentObject(planningViewModel)
                .preferredColorScheme(preferencesManager.isDarkTheme ? .dark : .light)
                .task {
                    // Tops the rolling window back up, drops today's reminder if
                    // something has already been logged, and re-localises the text
                    // if the language changed.
                    await ReminderScheduler().refresh(
                        isEnabled: preferencesManager.reminderEnabled,
                        hour: preferencesManager.reminderHour,
                        minute: preferencesManager.reminderMinute,
                        expenses: expenseViewModel.expenses
                    )
                }
        }
    }
}
