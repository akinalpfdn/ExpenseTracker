//
//  TourStep.swift
//  ExpenseTracker
//
//  The guided tour's script: eight steps, one screen at a time, in order.
//
//  Short on purpose. A tour is not a feature inventory — it is the path to the user's
//  first success plus enough of a look around that they know where things are. Every
//  step points at one real control; the overlay dims everything except that control.
//

import Foundation
import SwiftUI

// MARK: - Where a Step Lives

/// The tab a step's target sits on. The controller publishes this and the root view
/// switches to it, so the target is on screen before the spotlight opens.
enum TourTab: Int {
    case overview = 0
    case expenses = 1
    case analysis = 2
    case planning = 3
}

// MARK: - Which Hierarchy a Step Is Drawn In

/// A sheet is a separate view hierarchy presented above the whole app, so an overlay
/// rooted in the main view can never appear inside one. Each surface hosts its own
/// overlay and draws only the steps that belong to it.
enum TourSurface {
    case main
    case addExpenseForm
}

// MARK: - Step Identity

/// Each case is also the identifier a view uses to register itself as the target:
/// `.tourTarget(.addExpense)`. That one-to-one rule is what keeps the tooltip and the
/// spotlight on the same thing.
enum TourStepID: String, CaseIterable {
    case addExpense
    case saveExpense
    case expenseList
    case monthlyRing
    case recurringList
    case overview
    case analysis
    case planning
    case settings
}

// MARK: - Step

struct TourStep: Identifiable, Equatable {
    let id: TourStepID
    let tab: TourTab
    var surface: TourSurface = .main

    /// Localization key stem — `tour_<key>_title` and `tour_<key>_message`.
    let key: String

    /// An action step waits for the user to actually tap the spotlit control. It has
    /// no Next button; the control itself is the only way forward, and the overlay
    /// lets touches through to it and nothing else.
    let requiresAction: Bool

    /// The form needs several of its controls used before the spotlit one, so it is
    /// not dimmed — the callout and the pulse are guidance, not a fence.
    var dimsBackground: Bool { surface == .main }

    var title: String { "tour_\(key)_title".localized }
    var message: String { "tour_\(key)_message".localized }

    static func == (lhs: TourStep, rhs: TourStep) -> Bool { lhs.id == rhs.id }
}

// MARK: - The Script

extension TourStep {

    static let script: [TourStep] = [
        // The one thing the user has to do. Everything else the app shows is derived
        // from expenses, so the tour is empty talk until there is one.
        TourStep(id: .addExpense, tab: .expenses, key: "add_expense", requiresAction: true),

        // Inside the form. Tapping the plus completes the step above and opens the
        // sheet; saving completes this one. Cancelling the sheet returns to the plus.
        TourStep(id: .saveExpense, tab: .expenses, surface: .addExpenseForm, key: "save_expense", requiresAction: true),

        // The rest of the expense screen, now that there is something on it.
        TourStep(id: .expenseList, tab: .expenses, key: "expense_list", requiresAction: false),
        TourStep(id: .monthlyRing, tab: .expenses, key: "monthly_ring", requiresAction: false),
        TourStep(id: .recurringList, tab: .expenses, key: "recurring_list", requiresAction: false),

        // One look at each of the other tabs.
        TourStep(id: .overview, tab: .overview, key: "overview", requiresAction: false),
        TourStep(id: .analysis, tab: .analysis, key: "analysis", requiresAction: false),
        TourStep(id: .planning, tab: .planning, key: "planning", requiresAction: false),

        // Back on the expense screen, where the gear is.
        TourStep(id: .settings, tab: .expenses, key: "settings", requiresAction: false)
    ]
}
