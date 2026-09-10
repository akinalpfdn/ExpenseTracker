//
//  TutorialTests.swift
//  ExpenseTrackerTests
//
//  Sequencing, chapter boundaries and the rules that stop the tour stranding anyone.
//

import XCTest
@testable import ExpenseTracker

@MainActor
final class TutorialManagerTests: XCTestCase {

    private func makeManager() -> TutorialManager {
        return TutorialManager(preferencesManager: PreferencesManager())
    }

    // MARK: - Starting

    func testStartsInactive() {
        XCTAssertFalse(makeManager().isActive)
        XCTAssertNil(makeManager().currentStep)
    }

    func testStartsOnTheFirstStepOfTheFirstChapter() {
        let manager = makeManager()
        manager.start()

        XCTAssertTrue(manager.isActive)
        XCTAssertEqual(manager.currentStepId, .addExpense)
        XCTAssertEqual(manager.currentStep?.chapter, .firstExpense)
    }

    func testCanStartFromAGivenChapter() {
        let manager = makeManager()
        manager.start(from: .screens)

        XCTAssertEqual(manager.currentStep?.chapter, .screens)
    }

    // MARK: - The Screen A Step Needs

    /// The tab has to be on display before the tooltip pointing at it appears.
    func testPublishesTheScreenTheCurrentStepBelongsTo() {
        let manager = makeManager()
        manager.start()

        XCTAssertEqual(manager.requestedScreen, .expenses)
    }

    func testTheTourVisitsEveryTab() {
        let screens = Set(TutorialStep.script().map(\.screen))

        XCTAssertTrue(screens.contains(.overview))
        XCTAssertTrue(screens.contains(.expenses))
        XCTAssertTrue(screens.contains(.analysis))
        XCTAssertTrue(screens.contains(.planning))
    }

    // MARK: - Action Steps

    /// The point of an action step: Next must not move it along, or the button and the
    /// rule would disagree.
    func testNextDoesNothingOnAnActionStep() {
        let manager = makeManager()
        manager.start()

        XCTAssertTrue(manager.isWaitingForUserAction)
        manager.next()

        XCTAssertEqual(manager.currentStepId, .addExpense, "Next moved an action step along")
    }

    func testTheRealActionAdvancesIt() {
        let manager = makeManager()
        manager.start()

        manager.completeAction(.addExpense)

        XCTAssertEqual(manager.currentStepId, .fillForm)
    }

    /// A tap somewhere else in the app, during a different step, must not push the
    /// tour forward.
    func testAnActionForAnotherStepIsIgnored() {
        let manager = makeManager()
        manager.start()

        manager.completeAction(.planningPlans)

        XCTAssertEqual(manager.currentStepId, .addExpense)
    }

    /// The escape hatch. Whatever the user taps, they can always get out of a step.
    func testSkippingAStepMovesOn() {
        let manager = makeManager()
        manager.start()

        manager.skipStep()

        XCTAssertEqual(manager.currentStepId, .fillForm)
    }

    /// Cancelling the expense form should put the tour back on the step that asked
    /// the user to open it, not leave "fill it in" pointing at a form that has gone.
    func testAbandoningAnActionReturnsToTheStepThatAskedForIt() {
        let manager = makeManager()
        manager.start()
        manager.completeAction(.addExpense)

        XCTAssertEqual(manager.currentStepId, .fillForm)

        manager.returnTo(.addExpense)

        XCTAssertEqual(manager.currentStepId, .addExpense)
        XCTAssertTrue(manager.isWaitingForUserAction)
    }

    /// Only ever backwards. Otherwise a stray dismiss could jump the tour forward.
    func testReturningToALaterStepDoesNothing() {
        let manager = makeManager()
        manager.start()

        manager.returnTo(.planningPlans)

        XCTAssertEqual(manager.currentStepId, .addExpense)
    }

    func testReturningWhileInactiveDoesNothing() {
        let manager = makeManager()
        manager.returnTo(.addExpense)

        XCTAssertFalse(manager.isActive)
    }

    // MARK: - Ordinary Steps

    func testNextAdvancesAnOrdinaryStep() {
        let manager = makeManager()
        manager.start()
        manager.skipStep()   // past addExpense
        manager.skipStep()   // past fillForm

        XCTAssertEqual(manager.currentStepId, .expenseList)
        XCTAssertFalse(manager.isWaitingForUserAction)

        manager.next()
        XCTAssertEqual(manager.currentStepId, .progressRing)
    }

    // MARK: - Going Back

    /// Nothing precedes the opening step.
    func testNoBackOnTheFirstStep() {
        let manager = makeManager()
        manager.start()

        XCTAssertFalse(manager.canGoBack)
    }

    /// Chapter one opens with two action steps, and back skips over those, so there is
    /// nowhere to go until the tour reaches a step that merely describes something.
    func testNoBackWhileOnlyActionStepsPrecede() {
        let manager = makeManager()
        manager.start()
        manager.skipStep()   // addExpense
        manager.skipStep()   // fillForm

        XCTAssertEqual(manager.currentStepId, .expenseList)
        XCTAssertFalse(manager.canGoBack, "Back would land on an action already done")
    }

    func testBackReturnsToThePreviousDescribingStep() {
        let manager = makeManager()
        manager.start()
        manager.skipStep()
        manager.skipStep()
        manager.next()   // expenseList -> progressRing

        XCTAssertTrue(manager.canGoBack)
        manager.previous()

        XCTAssertEqual(manager.currentStepId, .expenseList)
    }

    /// Landing on an action step going backwards would show a prompt for something the
    /// user has already done, waiting for an interaction that cannot happen again.
    func testBackNeverLandsOnAnActionStep() {
        let manager = makeManager()
        manager.start(from: .screens)

        // Walk to the end of the tour, stepping back at every opportunity.
        while manager.isActive {
            if manager.canGoBack {
                manager.previous()
                XCTAssertFalse(
                    manager.isWaitingForUserAction,
                    "Stepped back onto \(String(describing: manager.currentStepId))"
                )
            }
            manager.isWaitingForUserAction ? manager.skipStep() : manager.next()
            if case .chapterBreak = manager.phase { manager.continueToNextChapter() }
        }
    }

    /// The break card invites you onwards; showing it to someone heading back would
    /// read as a dead end.
    func testBackAcrossAChapterBoundaryGoesStraightToTheStep() {
        let manager = makeManager()
        manager.start(from: .screens)

        XCTAssertEqual(manager.currentStepId, .calendar)
        manager.previous()

        XCTAssertEqual(manager.currentStep?.chapter, .firstExpense)
        if case .chapterBreak = manager.phase {
            XCTFail("Going back re-showed the chapter break")
        }
    }

    func testBackDoesNothingDuringAChapterBreak() {
        let manager = makeManager()
        manager.start()
        runOutChapter(manager)

        XCTAssertFalse(manager.canGoBack)
        manager.previous()

        guard case .chapterBreak = manager.phase else {
            return XCTFail("Back disturbed the chapter break")
        }
    }

    // MARK: - Chapter Boundaries

    func testACharacterBoundaryPausesForAnOffer() {
        let manager = makeManager()
        manager.start()

        // Run out the first chapter.
        for _ in TutorialStep.steps(in: .firstExpense) {
            manager.isWaitingForUserAction ? manager.skipStep() : manager.next()
        }

        guard case .chapterBreak(let finished, let next) = manager.phase else {
            return XCTFail("Expected a chapter break, got \(manager.phase)")
        }

        XCTAssertEqual(finished, .firstExpense)
        XCTAssertEqual(next, .screens)
    }

    func testContinuingFromABreakEntersTheNextChapter() {
        let manager = makeManager()
        manager.start()
        runOutChapter(manager)

        manager.continueToNextChapter()

        XCTAssertEqual(manager.currentStep?.chapter, .screens)
    }

    /// Stopping at a break is not the same as finishing — the tour is not marked done,
    /// so it can be offered again.
    func testStoppingAtABreakLeavesTheTourUnfinished() {
        let manager = makeManager()
        manager.start()
        runOutChapter(manager)

        manager.pauseAtChapterBreak()

        XCTAssertFalse(manager.isActive)
        XCTAssertNil(manager.requestedScreen)
    }

    // MARK: - Ending

    func testSkippingTheTourEndsIt() {
        let manager = makeManager()
        manager.start()

        manager.skipTour()

        XCTAssertFalse(manager.isActive)
        XCTAssertNil(manager.requestedScreen)
    }

    func testRunningOffTheEndFinishes() {
        let manager = makeManager()
        manager.start(from: .makingItYours)

        for _ in TutorialStep.steps(in: .makingItYours) {
            manager.isWaitingForUserAction ? manager.skipStep() : manager.next()
        }

        XCTAssertFalse(manager.isActive, "The last chapter should end the tour, not break")
    }

    // MARK: - The Script

    func testChaptersAreContiguous() {
        let chapters = TutorialStep.script().map(\.chapter.rawValue)

        // Once a chapter is left it is never returned to, which is what makes a
        // boundary a boundary.
        XCTAssertEqual(chapters, chapters.sorted())
    }

    func testEveryChapterHasSteps() {
        for chapter in TutorialChapter.allCases {
            XCTAssertFalse(
                TutorialStep.steps(in: chapter).isEmpty,
                "\(chapter) has no steps, so its break would offer nothing"
            )
        }
    }

    func testStepIdsAreUnique() {
        let ids = TutorialStep.script().map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "A duplicate id would break completeAction")
    }

    /// Only the first chapter insists on real interaction. A later one doing so would
    /// mean a user who skipped ahead could get stuck on something they cannot see.
    func testOnlyTheFirstChapterAsksForAction() {
        for step in TutorialStep.script() where step.requiresUserAction {
            XCTAssertEqual(step.chapter, .firstExpense, "\(step.id) demands an action outside chapter one")
        }
    }

    // MARK: - Helper

    private func runOutChapter(_ manager: TutorialManager) {
        guard let chapter = manager.currentStep?.chapter else { return }

        while manager.currentStep?.chapter == chapter {
            manager.isWaitingForUserAction ? manager.skipStep() : manager.next()
        }
    }
}
