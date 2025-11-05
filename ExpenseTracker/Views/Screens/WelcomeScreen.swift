//
//  WelcomeScreen.swift
//  ExpenseTracker
//
//  Created by migration from Android WelcomeScreen.kt
//

import SwiftUI

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String  // SF Symbol name
    let gradient: [Color]
}

struct WelcomeScreen: View {
    let onFinish: () -> Void
    let isDarkTheme: Bool

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "welcome_page1_title".localized,
            description: "welcome_page1_description".localized,
            icon: "dollarsign.circle.fill",
            gradient: [Color(red: 0.4, green: 0.494, blue: 0.918), Color(red: 0.463, green: 0.294, blue: 0.635)]
        ),
        OnboardingPage(
            title: "welcome_page2_title".localized,
            description: "welcome_page2_description".localized,
            icon: "chart.bar.fill",
            gradient: [Color(red: 0.941, green: 0.58, blue: 0.984), Color(red: 0.961, green: 0.341, blue: 0.424)]
        ),
        OnboardingPage(
            title: "welcome_page3_title".localized,
            description: "welcome_page3_description".localized,
            icon: "lock.shield.fill",
            gradient: [Color(red: 0.31, green: 0.675, blue: 0.996), Color(red: 0.0, green: 0.949, blue: 0.996)]
        )
    ]

    var body: some View {
        ZStack {
            ThemeColors.getBackgroundColor(isDarkTheme: isDarkTheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: onFinish) {
                        Text("welcome_skip".localized)
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    }
                }
                .padding(16)

                // Pager
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageContent(
                            page: pages[index],
                            isDarkTheme: isDarkTheme
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(
                                currentPage == index ?
                                AppColors.primaryOrange :
                                ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme).opacity(0.3)
                            )
                            .frame(
                                width: currentPage == index ? 32 : 8,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Bottom button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onFinish()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "welcome_next".localized : "welcome_get_started".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppColors.primaryOrange)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

struct OnboardingPageContent: View {
    let page: OnboardingPage
    let isDarkTheme: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }

            Spacer().frame(height: 48)

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 16)

            // Description
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// MARK: - Preview
struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen(onFinish: {}, isDarkTheme: true)
    }
}
