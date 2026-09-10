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

    /// Tapping the plus hands over to the form's own step.
    func testTappingThePlusMovesIntoTheForm() {
        let tour = makeTour()
        tour.startIfNeeded()

        tour.complete(.addExpense)

        XCTAssertEqual(tour.current?.id, .saveExpense)
        XCTAssertEqual(tour.current?.surface, .addExpenseForm)
        XCTAssertFalse(tour.current?.dimsBackground ?? true, "The form must stay usable")
    }

    func testSavingCompletesTheForm() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)

        tour.complete(.saveExpense)

        XCTAssertEqual(tour.current?.id, .expenseList)
    }

    /// Cancelling the form returns to the plus that opened it. After a save the tour
    /// has already moved on and the same call must do nothing.
    func testCancellingTheFormReturnsToThePlus() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)

        tour.retreat(from: .saveExpense, to: .addExpense)

        XCTAssertEqual(tour.current?.id, .addExpense)
    }

    func testRetreatAfterASaveDoesNothing() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.complete(.saveExpense)

        tour.retreat(from: .saveExpense, to: .addExpense)

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

        XCTAssertEqual(tour.current?.id, .saveExpense)
    }

    // MARK: - Information Steps

    func testNextWalksTheScript() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.complete(.saveExpense)

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
    func testNoBackFromTheStepAfterTheActions() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.complete(.saveExpense)

        XCTAssertEqual(tour.current?.id, .expenseList)
        XCTAssertFalse(tour.canGoBack)
    }

    func testBackReturnsToThePreviousInformationStep() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.complete(.saveExpense)
        tour.next()

        XCTAssertEqual(tour.current?.id, .monthlyRing)
        tour.back()

        XCTAssertEqual(tour.current?.id, .expenseList)
    }

    func testBackNeverLandsOnAnActionStep() {
        let tour = makeTour()
        tour.startIfNeeded()
        tour.complete(.addExpense)
        tour.complete(.saveExpense)

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

    /// The action steps are the first two — open the form, save an expense — and
    /// nothing after. A later action step could strand someone who has jumped to a
    /// screen whose control they cannot find.
    func testOnlyTheFirstTwoStepsRequireAction() {
        let flags = TourStep.script.map(\.requiresAction)
        XCTAssertEqual(flags.prefix(2), [true, true])
        XCTAssertFalse(flags.dropFirst(2).contains(true))
    }

    /// The form step is the only one drawn inside a sheet, and the only one that
    /// leaves the screen undimmed.
    func testOnlyTheFormStepLivesInTheForm() {
        let inForm = TourStep.script.filter { $0.surface == .addExpenseForm }
        XCTAssertEqual(inForm.map(\.id), [.saveExpense])
        XCTAssertEqual(TourStep.script.filter { !$0.dimsBackground }.map(\.id), [.saveExpense])
    }

    func testEveryStepIdHasAScriptEntry() {
        let scripted = Set(TourStep.script.map(\.id))
        for id in TourStepID.allCases {
            XCTAssertTrue(scripted.contains(id), "\(id) is declared but never used")
        }
    }
}
