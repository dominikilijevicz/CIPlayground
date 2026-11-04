import XCTest

/// UI tests run the real app in a simulator. They are slower and flakier than
/// unit tests, so CI runs them as a separate, clearly-labelled job.
final class CounterUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    func testCounterStartsAtZero() {
        let app = launchApp()
        let value = app.staticTexts["counterValue"]
        XCTAssertTrue(value.waitForExistence(timeout: 10))
        XCTAssertEqual(value.label, "0")
    }

    func testIncrementUpdatesTheDisplayedValue() {
        let app = launchApp()
        let value = app.staticTexts["counterValue"]
        XCTAssertTrue(value.waitForExistence(timeout: 10))

        app.buttons["incrementButton"].tap()
        app.buttons["incrementButton"].tap()

        XCTAssertEqual(value.label, "2")
    }

    func testResetReturnsToZero() {
        let app = launchApp()
        let value = app.staticTexts["counterValue"]
        XCTAssertTrue(value.waitForExistence(timeout: 10))

        app.buttons["incrementButton"].tap()
        app.buttons["resetButton"].tap()

        XCTAssertEqual(value.label, "0")
    }

    func testDecrementIsDisabledAtZero() {
        let app = launchApp()
        let decrement = app.buttons["decrementButton"]
        XCTAssertTrue(decrement.waitForExistence(timeout: 10))
        XCTAssertFalse(decrement.isEnabled)
    }
}
