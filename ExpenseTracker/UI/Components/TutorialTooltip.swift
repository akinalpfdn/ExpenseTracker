//
//  TutorialTooltip.swift
//  ExpenseTracker
//
//  The card at the bottom of the screen during the tour, and the card shown between
//  chapters.
//

import SwiftUI

// MARK: - Step Tooltip

struct TutorialTooltip: View {
    let step: TutorialStep
    let stepNumber: Int
    let totalSteps: Int
    let isDarkTheme: Bool

    let canGoBack: Bool

    let onBack: () -> Void
    let onNext: () -> Void
    let onSkipStep: () -> Void
    let onSkipTour: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                header
                message
                actions
            }
            .padding(20)
            .background(ThemeColors.getDialogBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
            .padding(20)
        }
    }
}

private extension TutorialTooltip {

    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(step.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Text("\(stepNumber)/\(totalSteps)")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
        }
    }

    var message: some View {
        Text(step.message)
            .font(.system(size: 14))
            .lineSpacing(4)
            .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// An action step has no Next — the way forward is to do the thing. It gets its own
    /// skip instead, always visible rather than appearing after some timeout, so
    /// someone who tapped the wrong place is never left guessing.
    var actions: some View {
        HStack(spacing: 16) {
            Button("tutorial_skip_tour".localized, action: onSkipTour)
                .font(.system(size: 13))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

            Spacer()

            if canGoBack {
                Button(action: onBack) {
                    Label("tutorial_back".localized, systemImage: "chevron.left")
                        .font(.system(size: 13))
                        .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                }
            }

            if step.requiresUserAction {
                Button("tutorial_skip_step".localized, action: onSkipStep)
                    .font(.system(size: 13))
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))

                Label("tutorial_your_turn".localized, systemImage: "hand.tap")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryOrange)
            } else {
                Button("tutorial_next".localized, action: onNext)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryOrange)
            }
        }
    }
}

// MARK: - Chapter Break

/// Shown when a chapter ends. Stopping here is a first-class option: the tour
/// remembers where it was and Settings can offer to pick it up.
struct TutorialChapterBreak: View {
    let finished: TutorialChapter
    let next: TutorialChapter
    let isDarkTheme: Bool

    let onContinue: () -> Void
    let onStop: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Label(finished.title, systemImage: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ThemeColors.getSuccessGreenColor(isDarkTheme: isDarkTheme))

                Text(next.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

                Text(next.invitation)
                    .font(.system(size: 14))
                    .lineSpacing(4)
                    .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button(action: onStop) {
                        Text("tutorial_stop_here".localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(ThemeColors.getButtonDisabledColor(isDarkTheme: isDarkTheme))
                            .cornerRadius(14)
                    }

                    Button(action: onContinue) {
                        Text("tutorial_continue".localized)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.textWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(AppColors.primaryOrange)
                            .cornerRadius(14)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(ThemeColors.getDialogBackgroundColor(isDarkTheme: isDarkTheme))
            .cornerRadius(20)
            .padding(28)
        }
    }
}

// MARK: - Overlay

/// Sits above the whole app and renders whichever card the tour's phase calls for.
///
/// Lives at the tab view rather than inside a screen, so a step can point at something
/// on any tab without each screen carrying its own copy of the tour chrome.
struct TutorialOverlay: View {
    @ObservedObject var manager: TutorialManager
    let isDarkTheme: Bool

    var body: some View {
        switch manager.phase {
        case .inactive:
            EmptyView()

        case .running(let step):
            TutorialTooltip(
                step: step,
                stepNumber: manager.stepNumber,
                totalSteps: manager.totalSteps,
                isDarkTheme: isDarkTheme,
                canGoBack: manager.canGoBack,
                onBack: { manager.previous() },
                onNext: { manager.next() },
                onSkipStep: { manager.skipStep() },
                onSkipTour: { manager.skipTour() }
            )

        case .chapterBreak(let finished, let next):
            TutorialChapterBreak(
                finished: finished,
                next: next,
                isDarkTheme: isDarkTheme,
                onContinue: { manager.continueToNextChapter() },
                onStop: { manager.pauseAtChapterBreak() }
            )
        }
    }
}
