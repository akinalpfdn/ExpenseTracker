//
//  RateMeView.swift
//  ExpenseTracker
//
//  Created for app rating functionality
//

import SwiftUI
import StoreKit

struct RateMeView: View {
    @Environment(\.isDarkTheme) private var isDarkTheme
    @ObservedObject var preferencesManager = PreferencesManager.shared

    let onRate: () -> Void
    let onRemindLater: () -> Void
    let onNever: () -> Void

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss on background tap
                    onRemindLater()
                }

            // Main dialog
            VStack(spacing: 0) {
                // Dialog content
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "star.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white)
                    }

                    // Title and description
                    VStack(spacing: 12) {
                        Text("rate_app_title".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                        Text("rate_app_description".localized)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                            .padding(.horizontal, 8)
                    }

                    // Star rating (non-interactive, just for show)
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(24)

                // Buttons
                VStack(spacing: 12) {
                    // Rate App button
                    Button(action: {
                        onRate()
                    }) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 20))
                            Text("rate_app_button".localized)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColors.primaryButtonGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Remind Later button
                    Button(action: {
                        onRemindLater()
                    }) {
                        Text("remind_later_button".localized)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(ThemeColors.getInputBackgroundColor(isDarkTheme: isDarkTheme))
                            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                            .cornerRadius(12)
                    }

                    // Never Ask button
                    Button(action: {
                        onNever()
                    }) {
                        Text("never_ask_button".localized)
                            .font(.caption)
                            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(
                ThemeColors.getDialogBackgroundColor(isDarkTheme: isDarkTheme)
                    .cornerRadius(16)
            )
            .padding(.horizontal, 32)
            .scaleEffect(0.95)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: true)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.8)),
            removal: .opacity.combined(with: .scale(scale: 1.1))
        ))
    }
}

// MARK: - Rate Me Manager

class RateMeManager: ObservableObject {
    @Published var showRateMe = false

    func checkAndShowRateMe() {
        let preferences = PreferencesManager.shared
        if preferences.shouldShowRateMeReminder() {
            showRateMe = true
        }
    }

    func requestAppStoreReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        PreferencesManager.shared.setAppRated()
        showRateMe = false
    }

    func remindLater() {
        showRateMe = false
        // Reset the rating flag so it can be shown again next launch
        // For debugging, this allows showing every launch
    }

    func neverAsk() {
        PreferencesManager.shared.setAppRated()
        showRateMe = false
    }
}

// MARK: - Preview

#Preview {
    RateMeView(
        onRate: {},
        onRemindLater: {},
        onNever: {}
    )
    .themeMode(true)
}