//
//  TourControllerTests.swift
//  ExpenseTrackerTests
//
//  Sequencing and the rules that stop the tour ever stranding anyone.
//

import XCTest
@testable import ExpenseTracker

@MainActor
final class TourControllerTests: XCTestCase {

    private func makeTour(completed: Bool = false) -> TourController {
        let preferences = PreferencesManager()
        completed ? preferences.setTutorialCompleted() : preferences.resetTutorial()
        return TourController(preferences: preferences)
    }

    // MARK: - Starting

    func testStartsInactive() {
        XCTAssertFalse(makeTour().isActive)
    }

    func testStartsOnTheActionStep() {
        let tour = makeTour()
        tour.startIfNeeded()

        XCTAssertEqual(tour.current?.id, .addExpense)
        XCTAssertTrue(tour.current?.requiresAction ?? false)
    }

    /// Someone who has been through it once is not shown it again on every launch.
    func testDoesNotStartWhenAlreadyCompleted() {
        let tour = makeTour(completed: true)
        tour.startIfNeeded()

        XCTAssertFalse(tour.isActive)
    }

    func testRestartRunsEvenWhenCompleted() {
        let tour = makeTour(completed: true)
        tour.restart()

        XCTAssertEqual(tour.current?.id, .addExpense)
    }

    // MARK: - The Action Step

    /// The point of an action step: the Next button does not exist for it, and the
    /// method behind that button refuses too, so the two can never disagree.
    func testNextDoesNothingOnTheActionStep() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.next()

        XCTAssertEqual(tour.current?.id, .addExpense)
    }

    func testCompletingTheActionAdvances() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.complete(.addExpense)

        XCTAssertEqual(tour.current?.id, .expenseList)
    }

    /// A stray report from some other control must not push the tour along.
    func testCompletingADifferentStepIsIgnored() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.complete(.settings)

        XCTAssertEqual(tour.current?.id, .addExpense)
    }

    /// The escape hatch: whatever the user did or did not tap, they can get out.
    func testSkippingTheActionStepAdvances() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.skipStep()

        XCTAssertEqual(tour.current?.id, .expenseList)
    }

    /// Cancelling the form completes nothing, so the tour is still on the action step
    /// when the sheet goes away. No rewind logic is needed because nothing moved.
    func testAnAbandonedActionLeavesTheTourWhereItWas() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.isSuspended = true      // sheet opened
        tour.isSuspended = false     // sheet closed without saving

        XCTAssertEqual(tour.current?.id, .addExpense)
    }

    // MARK: - Information Steps

    func testNextWalksTheScript() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)

        let expected: [TourStepID] = [.expenseList, .monthlyRing, .recurringList, .overview, .analysis, .planning, .settings]
        for id in expected {
            XCTAssertEqual(tour.current?.id, id)
            tour.next()
        }

        XCTAssertFalse(tour.isActive, "Next on the last step should finish the tour")
    }

    func testFinishingMarksTheTourCompleted() {
        let preferences = PreferencesManager()
        preferences.resetTutorial()
        let tour = TourController(preferences: preferences)

        tour.startIfNeeded()
        tour.skipTour()

        XCTAssertTrue(preferences.isTutorialCompleted())
        XCTAssertFalse(tour.isActive)
    }

    // MARK: - Going Back

    func testNoBackOnTheFirstStep() {
        let tour = makeTour()
        tour.startIfNeeded()

        XCTAssertFalse(tour.canGoBack)
    }

    /// Back never lands on an action step. Its precondition is gone — the expense is
    /// saved — so it would ask for something that cannot happen again.
    func testNoBackFromTheStepAfterTheAction() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)

        XCTAssertEqual(tour.current?.id, .expenseList)
        XCTAssertFalse(tour.canGoBack)
    }

    func testBackReturnsToThePreviousInformationStep() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.next()

        XCTAssertEqual(tour.current?.id, .monthlyRing)
        tour.back()

        XCTAssertEqual(tour.current?.id, .expenseList)
    }

    func testBackNeverLandsOnAnActionStep() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)

        while tour.isActive {
            if tour.canGoBack {
                tour.back()
                XCTAssertFalse(tour.current?.requiresAction ?? true)
                tour.next()
            }
            tour.next()
        }
    }

    // MARK: - Tabs

    /// The tour says which tab each step is on; the root view puts that tab up. Every
    /// tab must be visited or the tour is not showing the user the app.
    func testTheScriptVisitsEveryTab() {
        let tabs = Set(TourStep.script.map(\.tab))
        XCTAssertEqual(tabs, [.overview, .expenses, .analysis, .planning])
    }

    // MARK: - The Script

    func testStepIdsAreUnique() {
        let ids = TourStep.script.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// Exactly one step asks the user to do something, and it is the first. Later
    /// action steps could strand someone who has jumped to a screen whose control
    /// they cannot find.
    func testOnlyTheFirstStepRequiresAction() {
        let script = TourStep.script
        XCTAssertTrue(script.first?.requiresAction ?? false)
        XCTAssertFalse(script.dropFirst().contains { $0.requiresAction })
    }

    func testEveryStepIdHasAScriptEntry() {
        let scripted = Set(TourStep.script.map(\.id))
        for id in TourStepID.allCases {
            XCTAssertTrue(scripted.contains(id), "\(id) is declared but never used")
        }
    }
}
