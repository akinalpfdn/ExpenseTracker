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

    /// The overview, analysis and planning tabs.
    case screens = 1

    /// Everything behind the settings gear.
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
    // Chapter 1 — the expense screen
    case addExpense       // the orange + button
    case fillForm         // the add-expense sheet
    case expenseList      // the day's rows
    case weekStrip        // the seven-day strip at the top
    case monthlyRing      // the month total ring
    case recurringList    // the blue repeat button

    // Chapter 2 — the other three tabs
    case overviewSummary  // OverviewView.summaryCard
    case overviewTrend    // OverviewView.trendCard
    case overviewForecast // OverviewView.forecastCard
    case analysisPeriod   // AnalysisView.monthYearSelector
    case analysisFilter   // AnalysisView.expenseFilterTypeSelector
    case analysisBreakdown// AnalysisView pie chart
    case planningWhat     // PlanningView.headerSection
    case planningCreate   // PlanningView.floatingActionButton

    // Chapter 3 — everything behind the gear
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

    // MARK: Chapter 1 — The Expense Screen

    /// The only chapter that asks the user to act. Everything the app does starts with
    /// an expense in it, and a tour that describes that without doing it leaves someone
    /// staring at an empty list.
    private static func chapterOne() -> [TutorialStep] {
        return [
            step(.addExpense, .firstExpense, .expenses, "add_expense", .userAction, 70),
            step(.fillForm, .firstExpense, .expenses, "fill_form", .userAction, 90),
            step(.expenseList, .firstExpense, .expenses, "expense_list", .tapNext, 80),
            step(.weekStrip, .firstExpense, .expenses, "week_strip", .tapNext, 90),
            step(.monthlyRing, .firstExpense, .expenses, "monthly_ring", .tapNext, 150),
            step(.recurringList, .firstExpense, .expenses, "recurring_list", .tapNext, 70)
        ]
    }

    // MARK: Chapter 2 — The Other Screens

    /// Three tabs, and enough of each that the user knows why they would swipe there.
    /// One tooltip per screen was the previous shape and it explained nothing.
    private static func chapterTwo() -> [TutorialStep] {
        return [
            step(.overviewSummary, .screens, .overview, "overview_summary", .tapNext, 120),
            step(.overviewTrend, .screens, .overview, "overview_trend", .tapNext, 120),
            step(.overviewForecast, .screens, .overview, "overview_forecast", .tapNext, 120),

            step(.analysisPeriod, .screens, .analysis, "analysis_period", .tapNext, 100),
            step(.analysisFilter, .screens, .analysis, "analysis_filter", .tapNext, 100),
            step(.analysisBreakdown, .screens, .analysis, "analysis_breakdown", .tapNext, 130),

            step(.planningWhat, .screens, .planning, "planning_what", .tapNext, 120),
            step(.planningCreate, .screens, .planning, "planning_create", .tapNext, 70)
        ]
    }

    // MARK: Chapter 3 — Behind the Gear

    /// Every one of these lives inside the Settings sheet, which the tour cannot open
    /// and point inside of. The gear stays lit for the whole chapter instead — honest
    /// about where the user has to go, rather than glowing at unrelated controls.
    private static func chapterThree() -> [TutorialStep] {
        return [
            step(.settings, .makingItYours, .expenses, "settings", .tapNext, 55),
            step(.categories, .makingItYours, .expenses, "categories", .tapNext, 55),
            step(.limits, .makingItYours, .expenses, "limits", .tapNext, 55),
            step(.backup, .makingItYours, .expenses, "backup", .tapNext, 55),
            step(.reminder, .makingItYours, .expenses, "reminder", .tapNext, 55)
        ]
    }

    /// Keeps the script readable: the localization keys are always
    /// `tutorial_<name>_title` and `tutorial_<name>_message`, so naming them twice per
    /// step was only an opportunity to get one wrong.
    private static func step(
        _ id: TutorialStepId,
        _ chapter: TutorialChapter,
        _ screen: TutorialScreen,
        _ name: String,
        _ advance: TutorialAdvance,
        _ radius: CGFloat
    ) -> TutorialStep {
        return TutorialStep(
            id: id,
            chapter: chapter,
            screen: screen,
            title: "tutorial_\(name)_title".localized,
            message: "tutorial_\(name)_message".localized,
            advance: advance,
            highlightRadius: radius
        )
    }
}
