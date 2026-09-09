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

    /// Owned here rather than inside a screen, which is what lets the tour move between
    /// tabs. It publishes the screen it needs; the binding below puts it on display.
    @StateObject private var tutorialManager: TutorialManager

    init() {
        // The tour only reads and writes the tutorial-completed flag, which lives in
        // UserDefaults, so it does not need to share the environment's instance.
        _tutorialManager = StateObject(
            wrappedValue: TutorialManager(preferencesManager: PreferencesManager())
        )
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

            // The tour sits above everything so a step can point at any tab.
            TutorialOverlay(manager: tutorialManager, isDarkTheme: isDarkTheme)
                .zIndex(900)

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

    /// Waits a beat so the first screen has settled before a tooltip lands on it.
    private func startTourIfNeeded() {
        guard !preferencesManager.isTutorialCompleted(), !tutorialManager.isActive else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            tutorialManager.start()
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
                .environmentObject(tutorialManager)
                .onChange(of: tutorialManager.requestedScreen) { screen in
                    // A step declares which tab it belongs to; this is what puts that
                    // tab on display before its tooltip appears.
                    guard let screen = screen, selectedTab != screen.rawValue else { return }
                    withAnimation { selectedTab = screen.rawValue }
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
