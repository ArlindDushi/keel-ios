import Foundation

/// One build environment of the generated app. Each one gets a Debug and a Release
/// configuration, an xcconfig file and its own scheme.
public struct AppEnvironment: Identifiable, Hashable, Codable, Sendable {
    public var id = UUID()
    /// Human readable name, e.g. "Staging". Used for schemes, configurations and xcconfig files.
    public var name: String
    /// Appended to the bundle identifier, e.g. ".staging". Empty for the App Store build.
    public var bundleIDSuffix: String
    /// Appended to the display name, e.g. " Staging".
    public var displayNameSuffix: String
    public var apiBaseURL: String
    public var isProduction: Bool

    public init(
        name: String,
        bundleIDSuffix: String? = nil,
        displayNameSuffix: String? = nil,
        apiBaseURL: String = "https://api.example.com",
        isProduction: Bool = false
    ) {
        self.name = name
        self.isProduction = isProduction
        self.bundleIDSuffix = bundleIDSuffix ?? Self.suggestedBundleIDSuffix(for: name, isProduction: isProduction)
        self.displayNameSuffix = displayNameSuffix ?? Self.suggestedDisplayNameSuffix(for: name, isProduction: isProduction)
        self.apiBaseURL = apiBaseURL
    }

    public static let defaults: [AppEnvironment] = [
        AppEnvironment(name: "Dev", apiBaseURL: "https://dev.api.example.com"),
        AppEnvironment(name: "Staging", apiBaseURL: "https://staging.api.example.com"),
        AppEnvironment(name: "Production", apiBaseURL: "https://api.example.com", isProduction: true)
    ]

    public static func suggestedBundleIDSuffix(for name: String, isProduction: Bool) -> String {
        isProduction ? "" : "." + name.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    public static func suggestedDisplayNameSuffix(for name: String, isProduction: Bool) -> String {
        isProduction ? "" : " " + name
    }

    /// Swift enum case name, e.g. "staging".
    public var caseName: String {
        guard let first = name.first else { return name }
        return first.lowercased() + name.dropFirst()
    }

    /// Compilation condition, e.g. "STAGING".
    public var compilationCondition: String { name.uppercased() }

    public var debugConfigurationName: String { "\(name) Debug" }
    public var releaseConfigurationName: String { "\(name) Release" }
    public var xcconfigFileName: String { "\(name).xcconfig" }

    public func schemeName(appName: String) -> String { "\(appName) \(name)" }
}
