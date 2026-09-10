//
//  ExpenseTrackerUITestsLaunchTests.swift
//  ExpenseTrackerUITests
//
//  Created by Akinalp Fidan on 11.08.2025.
//

import XCTest

final class ExpenseTrackerUITestsLaunchTests: XCTestCase {

    // Xcode's template sets this to true, which runs the class once per UI
    // configuration — light/dark, left-to-right/right-to-left — each on a cloned
    // simulator, regardless of the scheme's parallel setting. Four clones for a test
    // that launches the app and takes a screenshot. Off.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
