//
//  ReminderScheduler.swift
//  ExpenseTracker
//
//  Keeps the queue of pending daily reminders in step with the user's settings and
//  what they have actually logged.
//

import Foundation
import UserNotifications

/// The slice of `UNUserNotificationCenter` this feature uses, so the scheduler can be
/// exercised without the real notification centre.
protocol NotificationCentre {
    func requestAuthorization() async -> Bool
    func isAuthorized() async -> Bool
    func pendingReminderIdentifiers() async -> [String]
    func removeReminders(withIdentifiers identifiers: [String])
    func add(identifier: String, title: String, body: String, fireDate: DateComponents) async
}

// MARK: - Real Implementation

struct SystemNotificationCentre: NotificationCentre {
    private var centre: UNUserNotificationCenter { .current() }

    func requestAuthorization() async -> Bool {
        do {
            return try await centre.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await centre.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    func pendingReminderIdentifiers() async -> [String] {
        let requests = await centre.pendingNotificationRequests()
        return requests.map(\.identifier).filter { $0.hasPrefix(ReminderScheduler.identifierPrefix) }
    }

    func removeReminders(withIdentifiers identifiers: [String]) {
        centre.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(identifier: String, title: String, body: String, fireDate: DateComponents) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Scheduler

actor ReminderScheduler {

    static let identifierPrefix = "daily-reminder-"

    private let centre: NotificationCentre
    private let planner: ReminderPlanner
    private let calendar: Calendar

    init(
        centre: NotificationCentre = SystemNotificationCentre(),
        planner: ReminderPlanner = ReminderPlanner(),
        calendar: Calendar = .current
    ) {
        self.centre = centre
        self.planner = planner
        self.calendar = calendar
    }

    // MARK: - Permission

    /// Asks the system, returning whether reminders can actually be delivered.
    /// The caller is expected to leave the setting off when this is false rather than
    /// showing a toggle that does nothing.
    func requestPermission() async -> Bool {
        return await centre.requestAuthorization()
    }

    func hasPermission() async -> Bool {
        return await centre.isAuthorized()
    }

    // MARK: - Scheduling

    /// Rebuilds the pending queue from scratch.
    ///
    /// Cheaper to reason about than diffing: cancel everything this feature owns, then
    /// add back what the planner says should exist. At fourteen entries the cost is
    /// irrelevant, and it means a changed time, a changed language and a newly logged
    /// day all take the same path.
    func refresh(
        isEnabled: Bool,
        hour: Int,
        minute: Int,
        expenses: [Expense],
        now: Date = Date()
    ) async {
        await cancelAll()

        guard isEnabled, await centre.isAuthorized() else { return }

        let loggedDays = planner.daysWithExpenses(from: expenses)
        let fireDates = planner.reminderDates(
            from: now,
            hour: hour,
            minute: minute,
            daysWithExpenses: loggedDays
        )

        // Localised here rather than at fire time, which is why a language change has
        // to go through a refresh to take effect on already-queued reminders.
        let title = "reminder_title".localized
        let body = "reminder_body".localized

        for fireDate in fireDates {
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )

            await centre.add(
                identifier: planner.identifier(for: fireDate),
                title: title,
                body: body,
                fireDate: components
            )
        }
    }

    func cancelAll() async {
        let pending = await centre.pendingReminderIdentifiers()
        guard !pending.isEmpty else { return }
        centre.removeReminders(withIdentifiers: pending)
    }
}
