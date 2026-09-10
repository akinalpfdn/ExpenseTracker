//
//  TourController.swift
//  ExpenseTracker
//
//  Which step is showing, and the handful of ways it can change. Lives at the root of
//  the app so it can move the tab; nothing about drawing lives here.
//

import Foundation
import SwiftUI

@MainActor
final class TourController: ObservableObject {

    /// The step on screen, or nil when the tour is not running.
    @Published private(set) var current: TourStep?

    /// True while a sheet is up. The overlay draws nothing in this state: a sheet is
    /// presented above the whole app, so anything the tour drew would sit behind it,
    /// and drawing inside sheets means two overlays fighting. The tour simply waits.
    @Published var isSuspended = false

    private let steps: [TourStep]
    private let preferences: PreferencesManager
    private var index = 0

    init(preferences: PreferencesManager, steps: [TourStep] = TourStep.script) {
        self.preferences = preferences
        self.steps = steps
    }

    // MARK: - Reading

    var isActive: Bool { current != nil }
    var stepNumber: Int { index + 1 }
    var totalSteps: Int { steps.count }
    var isLastStep: Bool { index == steps.count - 1 }

    /// Back skips over action steps. Their precondition is gone — the expense has
    /// been saved, the button already tapped — so landing on one would ask for
    /// something that cannot happen again.
    var canGoBack: Bool { previousIndex != nil }

    private var previousIndex: Int? {
        guard current != nil else { return nil }
        return (0..<index).reversed().first { !steps[$0].requiresAction }
    }

    // MARK: - Lifecycle

    /// Starts unless the user has already been through it.
    func startIfNeeded() {
        guard !preferences.isTutorialCompleted(), !isActive else { return }
        show(0)
    }

    /// The Settings replay control.
    func restart() {
        preferences.resetTutorial()
        show(0)
    }

    private func finish() {
        preferences.setTutorialCompleted()
        current = nil
        isSuspended = false
    }

    // MARK: - Moving

    /// The Next button. Refuses on an action step so the button and the rule can
    /// never disagree — an action step does not show the button anyway.
    func next() {
        guard let step = current, !step.requiresAction else { return }
        advance()
    }

    /// The screen reports that the spotlit control was actually used. Ignored unless
    /// that is the step showing, so a stray tap elsewhere cannot push the tour along.
    func complete(_ id: TourStepID) {
        guard current?.id == id else { return }
        advance()
    }

    /// Every action step offers this. Whatever the user did or did not tap, they can
    /// always get out of a step.
    func skipStep() {
        guard current != nil else { return }
        advance()
    }

    func back() {
        guard let target = previousIndex else { return }
        show(target)
    }

    func skipTour() {
        finish()
    }

    private func advance() {
        let nextIndex = index + 1
        if nextIndex < steps.count {
            show(nextIndex)
        } else {
            finish()
        }
    }

    private func show(_ newIndex: Int) {
        index = newIndex
        current = steps[newIndex]
    }
}
