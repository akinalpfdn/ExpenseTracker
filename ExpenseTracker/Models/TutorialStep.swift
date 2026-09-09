//
//  TutorialStep.swift
//  ExpenseTracker
//
//  The tour's script. A step knows which screen it belongs to, which chapter, and
//  whether it waits for the user to actually do something.
//

import Foundation
import SwiftUI

// MARK: - Where

/// The tab a step lives on. The tour drives the selection, so the right screen is on
/// display before its tooltip appears.
enum TutorialScreen: Int {
    case overview = 0
    case expenses = 1
    case analysis = 2
    case planning = 3
}

// MARK: - Chapters

/// The tour is broken up so the user can stop without abandoning it.
///
/// Thirteen steps in one run is worse onboarding than seven — people bail, and bailing
/// marks the whole thing finished. Chapters give a natural place to stop and somewhere
/// to resume from.
enum TutorialChapter: Int, CaseIterable {
    /// Add a real expense. The core loop, and the only chapter that insists.
    case firstExpense = 0

    /// What the other three tabs are for.
    case screens = 1

    /// Categories, limits, backup, reminders.
    case makingItYours = 2

    var title: String {
        switch self {
        case .firstExpense:  return "tutorial_chapter_first_expense".localized
        case .screens:       return "tutorial_chapter_screens".localized
        case .makingItYours: return "tutorial_chapter_making_it_yours".localized
        }
    }

    /// Shown at the break before the chapter starts.
    var invitation: String {
        switch self {
        case .firstExpense:  return "tutorial_chapter_first_expense_invite".localized
        case .screens:       return "tutorial_chapter_screens_invite".localized
        case .makingItYours: return "tutorial_chapter_making_it_yours_invite".localized
        }
    }
}

// MARK: - How a Step Advances

enum TutorialAdvance: Equatable {
    /// A Next button in the tooltip.
    case tapNext

    /// Waits for the real interaction the step is pointing at. No Next button — the
    /// only way forward is to do the thing, or to use the step's skip.
    case userAction
}

// MARK: - Steps

enum TutorialStepId: String, CaseIterable {
    // Chapter 1 — first expense
    case addExpense
    case fillForm
    case expenseList
    case progressRing

    // Chapter 2 — the screens
    case calendar
    case recurringExpenses
    case overviewSummary
    case overviewForecast
    case analysisCharts
    case planningPlans

    // Chapter 3 — making it yours
    case settings
    case categories
    case limits
    case backup
    case reminder
}

struct TutorialStep: Identifiable, Equatable {
    let id: TutorialStepId
    let chapter: TutorialChapter
    let screen: TutorialScreen
    let title: String
    let message: String
    let advance: TutorialAdvance

    /// Radius of the glow drawn around the element this step points at.
    let highlightRadius: CGFloat

    var requiresUserAction: Bool { advance == .userAction }

    static func == (lhs: TutorialStep, rhs: TutorialStep) -> Bool { lhs.id == rhs.id }
}

// MARK: - The Script

extension TutorialStep {

    static func script() -> [TutorialStep] {
        return chapterOne() + chapterTwo() + chapterThree()
    }

    static func steps(in chapter: TutorialChapter) -> [TutorialStep] {
        return script().filter { $0.chapter == chapter }
    }

    // MARK: Chapter 1 — First Expense

    /// The only chapter that asks the user to act. Everything the app does starts with
    /// an expense in it, and a tour that describes that without doing it leaves someone
    /// staring at an empty list.
    private static func chapterOne() -> [TutorialStep] {
        return [
            TutorialStep(
                id: .addExpense,
                chapter: .firstExpense,
                screen: .expenses,
                title: "tutorial_add_expense_title".localized,
                message: "tutorial_add_expense_message".localized,
                advance: .userAction,
                highlightRadius: 70
            ),
            TutorialStep(
                id: .fillForm,
                chapter: .firstExpense,
                screen: .expenses,
                title: "tutorial_fill_form_title".localized,
                message: "tutorial_fill_form_message".localized,
                advance: .userAction,
                highlightRadius: 90
            ),
            TutorialStep(
                id: .expenseList,
                chapter: .firstExpense,
                screen: .expenses,
                title: "tutorial_expense_list_title".localized,
                message: "tutorial_expense_list_message".localized,
                advance: .tapNext,
                highlightRadius: 80
            ),
            TutorialStep(
                id: .progressRing,
                chapter: .firstExpense,
                screen: .expenses,
                title: "tutorial_progress_ring_title".localized,
                message: "tutorial_progress_ring_message".localized,
                advance: .tapNext,
                highlightRadius: 90
            )
        ]
    }

    // MARK: Chapter 2 — The Screens

    private static func chapterTwo() -> [TutorialStep] {
        return [
            TutorialStep(
                id: .calendar,
                chapter: .screens,
                screen: .expenses,
                title: "tutorial_calendar_title".localized,
                message: "tutorial_calendar_message".localized,
                advance: .tapNext,
                highlightRadius: 150
            ),
            TutorialStep(
                id: .recurringExpenses,
                chapter: .screens,
                screen: .expenses,
                title: "tutorial_recurring_expenses_title".localized,
                message: "tutorial_recurring_expenses_message".localized,
                advance: .tapNext,
                highlightRadius: 70
            ),
            TutorialStep(
                id: .overviewSummary,
                chapter: .screens,
                screen: .overview,
                title: "tutorial_overview_summary_title".localized,
                message: "tutorial_overview_summary_message".localized,
                advance: .tapNext,
                highlightRadius: 120
            ),
            TutorialStep(
                id: .overviewForecast,
                chapter: .screens,
                screen: .overview,
                title: "tutorial_overview_forecast_title".localized,
                message: "tutorial_overview_forecast_message".localized,
                advance: .tapNext,
                highlightRadius: 120
            ),
            TutorialStep(
                id: .analysisCharts,
                chapter: .screens,
                screen: .analysis,
                title: "tutorial_analysis_title".localized,
                message: "tutorial_analysis_message".localized,
                advance: .tapNext,
                highlightRadius: 120
            ),
            TutorialStep(
                id: .planningPlans,
                chapter: .screens,
                screen: .planning,
                title: "tutorial_planning_title".localized,
                message: "tutorial_planning_message".localized,
                advance: .tapNext,
                highlightRadius: 120
            )
        ]
    }

    // MARK: Chapter 3 — Making It Yours

    private static func chapterThree() -> [TutorialStep] {
        return [
            TutorialStep(
                id: .settings,
                chapter: .makingItYours,
                screen: .expenses,
                title: "tutorial_settings_title".localized,
                message: "tutorial_settings_message".localized,
                advance: .tapNext,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .categories,
                chapter: .makingItYours,
                screen: .expenses,
                title: "tutorial_categories_title".localized,
                message: "tutorial_categories_message".localized,
                advance: .tapNext,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .limits,
                chapter: .makingItYours,
                screen: .expenses,
                title: "tutorial_limits_title".localized,
                message: "tutorial_limits_message".localized,
                advance: .tapNext,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .backup,
                chapter: .makingItYours,
                screen: .expenses,
                title: "tutorial_backup_title".localized,
                message: "tutorial_backup_message".localized,
                advance: .tapNext,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .reminder,
                chapter: .makingItYours,
                screen: .expenses,
                title: "tutorial_reminder_title".localized,
                message: "tutorial_reminder_message".localized,
                advance: .tapNext,
                highlightRadius: 55
            )
        ]
    }
}
