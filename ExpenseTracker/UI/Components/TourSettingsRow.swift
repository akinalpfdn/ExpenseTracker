//
//  TourSettingsRow.swift
//  ExpenseTracker
//
//  Replays the tour from Settings.
//

import SwiftUI

struct TourSettingsRow: View {
    @EnvironmentObject var tour: TourController

    let isDarkTheme: Bool

    /// Settings is a sheet, and the tour's first target is on the screen behind it.
    /// Closing the sheet is part of starting.
    let onDismissSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tour_replay_title".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Button(action: replay) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .medium))
                    Text("tour_replay_button".localized)
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

            Text("tour_replay_description".localized)
                .font(.system(size: 14))
                .foregroundColor(ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func replay() {
        onDismissSettings()

        // The sheet's dismissal suspends the tour until it is fully gone; a short wait
        // means the first spotlight opens on a settled screen rather than mid-animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tour.restart()
        }
    }
}
