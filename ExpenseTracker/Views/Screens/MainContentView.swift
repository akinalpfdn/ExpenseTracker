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

    @State private var selectedTab = 0

    private var isDarkTheme: Bool {
        preferencesManager.isDarkTheme
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                    .ignoresSafeArea()

                // Main content with TabView
                TabView(selection: $selectedTab) {
                    ExpensesView()
                        .environmentObject(expenseViewModel)
                        .tag(0)

                    AnalysisView(isDarkTheme: isDarkTheme)
                        .environmentObject(expenseViewModel)
                        .tag(1)

                    PlanningView(
                        isDarkTheme: isDarkTheme,
                        defaultCurrency: expenseViewModel.defaultCurrency
                    )
                    .environmentObject(planningViewModel)
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom page indicator at the bottom
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
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
