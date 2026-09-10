//
//  TutorialManager.swift
//  ExpenseTracker
//
//  Runs the tour: which step is showing, which screen it needs, and when a chapter has
//  ended.
//
//  This lives above the tab view rather than inside one screen, which is what lets the
//  tour move between tabs.
//

import Foundation
import SwiftUI

// MARK: - State

enum TutorialPhase: Equatable {
    case inactive

    /// A step is on screen.
    case running(TutorialStep)

    /// Between chapters, waiting for the user to continue or stop.
    case chapterBreak(finished: TutorialChapter, next: TutorialChapter)
}

@MainActor
class TutorialManager: ObservableObject {

    @Published private(set) var phase: TutorialPhase = .inactive

    /// The tab the tour needs on display. Nil when nothing is running.
    @Published private(set) var requestedScreen: TutorialScreen?

    private let preferencesManager: PreferencesManager
    private let script: [TutorialStep]
    private var currentIndex: Int = 0

    init(preferencesManager: PreferencesManager, script: [TutorialStep] = TutorialStep.script()) {
        self.preferencesManager = preferencesManager
        self.script = script
    }

    // MARK: - Reading

    var currentStep: TutorialStep? {
        if case .running(let step) = phase { return step }
        return nil
    }

    var currentStepId: TutorialStepId? { currentStep?.id }

    var isActive: Bool { phase != .inactive }

    /// Position within the whole tour, for the "3 / 15" counter.
    var stepNumber: Int { currentIndex + 1 }
    var totalSteps: Int { script.count }

    /// True when the tooltip must not offer a Next button.
    var isWaitingForUserAction: Bool { currentStep?.requiresUserAction ?? false }

    // MARK: - Starting

    func start(from chapter: TutorialChapter = .firstExpense) {
        guard let index = script.firstIndex(where: { $0.chapter == chapter }) else { return }
        move(to: index)
    }

    /// Used by the "replay the tour" control in Settings.
    func restart() {
        preferencesManager.resetTutorial()
        start()
    }

    // MARK: - Advancing

    /// The tooltip's Next button. Refuses on a step that is waiting for a real
    /// interaction, so the button and the rule cannot disagree.
    func next() {
        guard !isWaitingForUserAction else { return }
        advance()
    }

    /// Called by the screen when the user actually did the thing a step was pointing
    /// at. Ignored unless that exact step is showing, so a stray tap elsewhere in the
    /// app cannot push the tour forward.
    func completeAction(_ id: TutorialStepId) {
        guard currentStepId == id else { return }
        advance()
    }

    /// The per-step escape hatch. Every action step shows this, so tapping the wrong
    /// thing can never strand anyone.
    func skipStep() {
        advance()
    }

    /// Steps back to an earlier step, if that is where the tour currently is ahead of.
    ///
    /// Used when the user abandons the thing a step asked for — cancelling the expense
    /// form returns the tour to "tap the plus" rather than leaving "fill it in"
    /// pointing at a form that is no longer on screen.
    func returnTo(_ id: TutorialStepId) {
        guard isActive,
              let target = script.firstIndex(where: { $0.id == id }),
              target < currentIndex else {
            return
        }

        move(to: target)
    }

    private func advance() {
        let finishedChapter = currentStep?.chapter
        let nextIndex = currentIndex + 1

        guard nextIndex < script.count else {
            finish()
            return
        }

        let nextStep = script[nextIndex]

        // A chapter boundary is an offer, not a transition — the user gets to stop here
        // with the tour remembering where they were.
        if let finished = finishedChapter, nextStep.chapter != finished {
            currentIndex = nextIndex
            phase = .chapterBreak(finished: finished, next: nextStep.chapter)
            requestedScreen = nil
            return
        }

        move(to: nextIndex)
    }

    // MARK: - Chapter Breaks

    func continueToNextChapter() {
        guard case .chapterBreak = phase else { return }
        move(to: currentIndex)
    }

    /// Stops without marking the tour finished, so Settings can offer to pick it up.
    func pauseAtChapterBreak() {
        phase = .inactive
        requestedScreen = nil
    }

    // MARK: - Ending

    func skipTour() {
        finish()
    }

    private func finish() {
        preferencesManager.setTutorialCompleted()
        phase = .inactive
        requestedScreen = nil
    }

    private func move(to index: Int) {
        guard script.indices.contains(index) else { return finish() }

        currentIndex = index
        let step = script[index]

        phase = .running(step)
        requestedScreen = step.screen
    }
}
