//
//  TutorialManager.swift
//  ExpenseTracker
//
//  Manages tutorial state and progression
//

import Foundation
import SwiftUI

struct TutorialState {
    var isActive: Bool = false
    var currentStep: TutorialStep? = nil
    var currentStepIndex: Int = 0
    var totalSteps: Int = 0
    var canSkip: Bool = true
}

@MainActor
class TutorialManager: ObservableObject {
    @Published var state: TutorialState = TutorialState()

    private let preferencesManager: PreferencesManager
    private var steps: [TutorialStep] = []

    init(preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
        self.steps = TutorialStep.getDefaultSteps()
    }

    func startTutorial() {
        guard !steps.isEmpty else { return }

        state = TutorialState(
            isActive: true,
            currentStep: steps[0],
            currentStepIndex: 0,
            totalSteps: steps.count,
            canSkip: true
        )
    }

    func nextStep() {
        let currentIndex = state.currentStepIndex

        if currentIndex >= steps.count - 1 {
            // Tutorial completed
            completeTutorial()
        } else {
            let nextIndex = currentIndex + 1
            state.currentStep = steps[nextIndex]
            state.currentStepIndex = nextIndex
        }
    }

    func skipTutorial() {
        completeTutorial()
    }

    private func completeTutorial() {
        state = TutorialState(
            isActive: false,
            currentStep: nil,
            currentStepIndex: 0,
            totalSteps: steps.count,
            canSkip: false
        )

        // Save tutorial completion
        preferencesManager.setTutorialCompleted()
    }

    func resetTutorial() {
        preferencesManager.resetTutorial()
        startTutorial()
    }

    var currentStepId: TutorialStepId? {
        state.currentStep?.id
    }
}
