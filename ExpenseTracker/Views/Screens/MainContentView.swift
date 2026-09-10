//
//  MainContentView.swift
//  ExpenseTracker
//
//  Created by migration from Android MainScreen.kt
//

import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var expenseViewModel: ExpenseViewModel
    @EnvironmentObject var planningViewModel: PlanningViewModel
    @EnvironmentObject var preferencesManager: PreferencesManager

    /// Opens on the expense list, not on tab 0. Overview sits to its left as a place
    /// you swipe to, but the app should land where the daily work happens — adding and
    /// reading expenses — rather than on a summary.
    @State private var selectedTab = 1
    @StateObject private var rateMeManager = RateMeManager()

    /// Owned here, above the tab view, which is what lets the tour move between tabs.
    /// Each step names its tab; the binding below puts that tab on display.
    @StateObject private var tour: TourController

    init() {
        // The tour only reads and writes the tour-completed flag, which lives in
        // UserDefaults, so it does not need to share the environment's instance.
        _tour = StateObject(wrappedValue: TourController(preferences: PreferencesManager()))
    }

    private var isDarkTheme: Bool {
        preferencesManager.isDarkTheme
    }

    var body: some View {
        ZStack {
            Group {
                // Show loading or welcome screen based on state
                if let isFirstLaunch = preferencesManager.isFirstLaunch {
                    if isFirstLaunch {
                        // First launch - show welcome screen
                        WelcomeScreen(onComplete: {
                            preferencesManager.completeFirstLaunch()
                        })
                    } else {
                        // Not first launch - show main app
                        mainAppContent
                            .onAppear {
                                // Increment launch counter
                                preferencesManager.incrementLaunchCount()

                                // Check if we should show rate me dialog
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    rateMeManager.checkAndShowRateMe()
                                }

                                startTourIfNeeded()
                            }
                    }
                } else {
                    // Loading state - show splash
                    ZStack {
                        ThemeColors.getBackgroundColor(isDarkTheme: false)
                            .ignoresSafeArea()
                    }
                }
            }

            // Rate Me overlay
            if rateMeManager.showRateMe {
                RateMeView(
                    onRate: {
                        rateMeManager.requestAppStoreReview()
                    },
                    onRemindLater: {
                        rateMeManager.remindLater()
                    },
                    onNever: {
                        rateMeManager.neverAsk()
                    }
                )
                .themeMode(isDarkTheme)
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }

    /// Waits a beat so the first screen has settled before the spotlight opens on it.
    private func startTourIfNeeded() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            tour.startIfNeeded()
        }
    }

    private var mainAppContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                    .ignoresSafeArea()

                // Main content with TabView
                TabView(selection: $selectedTab) {
                    OverviewView(
                        isDarkTheme: isDarkTheme,
                        expenseViewModel: expenseViewModel,
                        preferencesManager: preferencesManager
                    )
                    .environmentObject(expenseViewModel)
                    .environmentObject(preferencesManager)
                    .tag(0)

                    ExpensesView()
                        .environmentObject(expenseViewModel)
                        .tag(1)

                    AnalysisView(isDarkTheme: isDarkTheme)
                        .environmentObject(expenseViewModel)
                        .tag(2)

                    PlanningView(
                        isDarkTheme: isDarkTheme,
                        defaultCurrency: expenseViewModel.defaultCurrency
                    )
                    .environmentObject(planningViewModel)
                    .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .environmentObject(tour)
                .onChange(of: tour.current?.tab) { tab in
                    // A step names the tab its target sits on; this is what puts that
                    // tab on display before the spotlight opens.
                    guard let tab = tab, selectedTab != tab.rawValue else { return }
                    withAnimation { selectedTab = tab.rawValue }
                }

                // Custom page indicator at the bottom
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    selectedTab == index ?
                                    AppColors.primaryOrange :
                                    ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.5)
                                )
                                .frame(
                                    width: selectedTab == index ? 24 : 8,
                                    height: 8
                                )
                                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        // Targets register their bounds up the tree; the overlay resolves the one the
        // current step wants and cuts the spotlight there. Attached here so every tab's
        // targets are in scope and the dim covers the tab content, not just one screen.
        .overlayPreferenceValue(TourTargetsKey.self) { targets in
            TourOverlayHost(tour: tour, targets: targets, isDarkTheme: isDarkTheme)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Preview
struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        let preferencesManager = PreferencesManager()
        let expenseViewModel = ExpenseViewModel()
        let planningViewModel = PlanningViewModel()

        MainContentView()
            .environmentObject(preferencesManager)
            .environmentObject(expenseViewModel)
            .environmentObject(planningViewModel)
    }
}
