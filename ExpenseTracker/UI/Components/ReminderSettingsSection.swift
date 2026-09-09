//
//  ReminderSettingsSection.swift
//  ExpenseTracker
//
//  Toggle and time picker for the daily reminder.
//

import SwiftUI

struct ReminderSettingsSection: View {
    @EnvironmentObject var preferencesManager: PreferencesManager
    @EnvironmentObject var expenseViewModel: ExpenseViewModel

    let isDarkTheme: Bool

    private let scheduler = ReminderScheduler()

    /// Set when the system refuses. Without this the toggle would flip back with no
    /// explanation and look broken.
    @State private var permissionDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("daily_reminder".localized)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            toggleRow

            if preferencesManager.reminderEnabled {
                timeRow
            }

            Text(permissionDenied ? "reminder_permission_denied".localized
                                  : "daily_reminder_description".localized)
                .font(.system(size: 14))
                .foregroundColor(
                    permissionDenied
                        ? ThemeColors.getDeleteRedColor(isDarkTheme: isDarkTheme)
                        : ThemeColors.getTextGrayColor(isDarkTheme: isDarkTheme)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .task {
            // The user can revoke notifications in system settings while the app is
            // backgrounded, which would leave the toggle claiming something untrue.
            await reconcileWithSystemPermission()
        }
    }
}

// MARK: - Rows

private extension ReminderSettingsSection {

    var toggleRow: some View {
        HStack {
            Text("reminder_enabled".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            Toggle("", isOn: Binding(
                get: { preferencesManager.reminderEnabled },
                set: { requested in
                    Task { await setEnabled(requested) }
                }
            ))
            .toggleStyle(CustomToggleStyle(isDarkTheme: isDarkTheme))
        }
    }

    var timeRow: some View {
        HStack {
            Text("reminder_time".localized)
                .font(.system(size: 16))
                .foregroundColor(ThemeColors.getTextColor(isDarkTheme: isDarkTheme))

            Spacer()

            DatePicker(
                "",
                selection: Binding(
                    get: { preferencesManager.reminderTime },
                    set: { newTime in
                        preferencesManager.reminderTime = newTime
                        Task { await refreshSchedule() }
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
}

// MARK: - Actions

private extension ReminderSettingsSection {

    func setEnabled(_ requested: Bool) async {
        guard requested else {
            preferencesManager.reminderEnabled = false
            permissionDenied = false
            await scheduler.cancelAll()
            return
        }

        // Permission is asked for here rather than at launch, when the user has no
        // idea what it would be for. The system only shows its prompt once, so a
        // second call after a refusal returns false without bothering anyone.
        var granted = await scheduler.hasPermission()
        if !granted {
            granted = await scheduler.requestPermission()
        }

        guard granted else {
            preferencesManager.reminderEnabled = false
            permissionDenied = true
            return
        }

        permissionDenied = false
        preferencesManager.reminderEnabled = true
        await refreshSchedule()
    }

    func refreshSchedule() async {
        await scheduler.refresh(
            isEnabled: preferencesManager.reminderEnabled,
            hour: preferencesManager.reminderHour,
            minute: preferencesManager.reminderMinute,
            expenses: expenseViewModel.expenses
        )
    }

    func reconcileWithSystemPermission() async {
        guard preferencesManager.reminderEnabled else { return }

        if await scheduler.hasPermission() {
            permissionDenied = false
        } else {
            preferencesManager.reminderEnabled = false
            permissionDenied = true
            await scheduler.cancelAll()
        }
    }
}
