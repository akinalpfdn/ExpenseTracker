//
//  TutorialSettingsSection.swift
//  ExpenseTracker
//
//  Replays the tour from Settings.
//

import SwiftUI

struct TutorialSettingsSection: View {
    @EnvironmentObject var tutorialManager: TutorialManager

    let isDarkTheme: Bool

    /// Closing Settings is part of the action: the tour points at controls on the
    /// screens behind this sheet, so leaving it open would hide everything it means.
    let onDismissSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tutorial_replay".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: replay) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .medium))

                    Text("tutorial_replay_button".localized)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.primaryOrange, lineWidth: 1)
                )
            }

            Text("tutorial_replay_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func replay() {
        onDismissSettings()

        // A beat for the sheet to get out of the way before the first tooltip lands.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            tutorialManager.restart()
        }
    }
}
