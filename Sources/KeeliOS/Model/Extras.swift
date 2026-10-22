import Foundation

public struct Extras: Hashable, Codable, Sendable {
    public var swiftLint = true
    public var tests = true
    public var fastlane = true
    public var gitInit = true
    /// Writes `project.yml` next to the project so it can be regenerated with the XcodeGen CLI.
    public var keepProjectSpec = false

    public init(swiftLint: Bool = true, tests: Bool = true, fastlane: Bool = true, gitInit: Bool = true, keepProjectSpec: Bool = false) {
        self.swiftLint = swiftLint
        self.tests = tests
        self.fastlane = fastlane
        self.gitInit = gitInit
        self.keepProjectSpec = keepProjectSpec
    }
}

public enum DeviceFamily: String, CaseIterable, Codable, Identifiable, Sendable {
    case iPhone
    case universal

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .iPhone: "iPhone"
        case .universal: "iPhone + iPad"
        }
    }

    var targetedDeviceFamily: String {
        switch self {
        case .iPhone: "1"
        case .universal: "1,2"
        }
    }
}
