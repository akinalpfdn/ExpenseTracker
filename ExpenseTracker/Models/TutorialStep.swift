//
//  TutorialStep.swift
//  ExpenseTracker
//
//  Tutorial system models
//

import Foundation
import SwiftUI

enum TutorialStepId: String, CaseIterable {
    case addExpense
    case recurringExpenses
    case calendar
    case dailyHistory
    case settings
    case secretArea
    case expenseList
}

struct TutorialStep: Identifiable {
    let id: TutorialStepId
    let title: String
    let message: String
    let requiresTap: Bool
    let highlightRadius: CGFloat

    static func getDefaultSteps() -> [TutorialStep] {
        return [
            TutorialStep(
                id: .addExpense,
                title: "tutorial_add_expense_title".localized,
                message: "tutorial_add_expense_message".localized,
                requiresTap: false,
                highlightRadius: 70
            ),
            TutorialStep(
                id: .recurringExpenses,
                title: "tutorial_recurring_expenses_title".localized,
                message: "tutorial_recurring_expenses_message".localized,
                requiresTap: false,
                highlightRadius: 70
            ),
            TutorialStep(
                id: .calendar,
                title: "tutorial_calendar_title".localized,
                message: "tutorial_calendar_message".localized,
                requiresTap: false,
                highlightRadius: 150
            ),
            TutorialStep(
                id: .dailyHistory,
                title: "tutorial_daily_history_title".localized,
                message: "tutorial_daily_history_message".localized,
                requiresTap: false,
                highlightRadius: 80
            ),
            TutorialStep(
                id: .settings,
                title: "tutorial_settings_title".localized,
                message: "tutorial_settings_message".localized,
                requiresTap: false,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .secretArea,
                title: "tutorial_secret_title".localized,
                message: "tutorial_secret_message".localized,
                requiresTap: false,
                highlightRadius: 55
            ),
            TutorialStep(
                id: .expenseList,
                title: "tutorial_expense_list_title".localized,
                message: "tutorial_expense_list_message".localized,
                requiresTap: false,
                highlightRadius: 80
            )
        ]
    }
}
