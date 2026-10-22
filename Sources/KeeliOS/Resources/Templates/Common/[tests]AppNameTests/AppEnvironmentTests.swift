import Foundation
import Testing
@testable import {{APP_NAME}}

struct AppEnvironmentTests {
    @Test func apiBaseURLIsAnHTTPURL() {
        #expect(["http", "https"].contains(AppEnvironment.apiBaseURL.scheme))
    }
}
