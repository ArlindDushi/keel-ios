import Foundation

/// The environment the app was built for. Every scheme builds a different one.
/// Values come from `Configuration/<Environment>.xcconfig` through Info.plist.
enum AppEnvironment: String, CaseIterable, Sendable {
    {{ENV_CASES}}

    static let current: AppEnvironment = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String,
              let environment = AppEnvironment(rawValue: value) else {
            fatalError("AppEnvironment is missing from Info.plist. Check the xcconfig files in Configuration/.")
        }
        return environment
    }()

    static let apiBaseURL: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: value) else {
            fatalError("APIBaseURL is missing from Info.plist. Check the xcconfig files in Configuration/.")
        }
        return url
    }()

    var isProduction: Bool { self == .{{PRODUCTION_ENV_CASE}} }
}
