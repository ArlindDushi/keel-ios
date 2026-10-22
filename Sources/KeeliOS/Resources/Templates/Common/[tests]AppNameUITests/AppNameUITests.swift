import XCTest

final class {{APP_NAME}}UITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsHome() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 10))
    }
}
