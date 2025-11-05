//
//  TutorialTooltip.swift
//  ExpenseTracker
//
//  Tutorial tooltip card component
//

import SwiftUI

struct TutorialTooltip: View {
    let step: TutorialStep
    let stepIndex: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    let isDarkTheme: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                // Step indicator
                HStack {
                    Text(step.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                    Spacer()

                    Text("\(stepIndex + 1)/\(totalSteps)")
                        .font(.system(size: 12))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }

                // Message
                Text(step.message)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                // Action buttons
                HStack {
                    Spacer()

                    Button("tutorial_skip".localized) {
                        onSkip()
                    }
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                    Spacer().frame(width: 8)

                    if !step.requiresTap {
                        Button(stepIndex == totalSteps - 1 ? "tutorial_finish".localized : "tutorial_next".localized) {
                            onNext()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.primaryOrange)
                    } else {
                        Text("tutorial_tap_to_continue".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.getCardBackgroundColor(isDarkTheme: isDarkTheme))
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step.id)
    }
}

// MARK: - Tutorial Overlay
struct TutorialOverlay: View {
    let tutorialState: TutorialState
    let onNext: () -> Void
    let onSkip: () -> Void
    let isDarkTheme: Bool

    var body: some View {
        if tutorialState.isActive, let currentStep = tutorialState.currentStep {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent tap through
                    }

                // Tooltip
                TutorialTooltip(
                    step: currentStep,
                    stepIndex: tutorialState.currentStepIndex,
                    totalSteps: tutorialState.totalSteps,
                    onNext: onNext,
                    onSkip: onSkip,
                    isDarkTheme: isDarkTheme
                )
            }
            .zIndex(999)
        }
    }
}

// MARK: - Preview
struct TutorialTooltip_Previews: PreviewProvider {
    static var previews: some View {
        let step = TutorialStep(
            id: .addExpense,
            title: "Add Expense",
            message: "Tap the + button to add your first expense",
            requiresTap: false,
            highlightRadius: 70
        )

        TutorialTooltip(
            step: step,
            stepIndex: 0,
            totalSteps: 7,
            onNext: {},
            onSkip: {},
            isDarkTheme: true
        )
    }
}
