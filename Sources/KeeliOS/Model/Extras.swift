import Foundation

public struct Extras: Hashable, Codable, Sendable {
    public var swiftLint = true
    public var tests = true
    public var fastlane = true
    public var gitInit = true
    /// Writes `project.yml` next to the project so it can be regenerated with the XcodeGen CLI.
    public var keepProjectSpec = false
    /// Writes `AGENTS.md`, `CLAUDE.md` and `docs/ARCHITECTURE.md` for coding agents.
    public var agentGuide = true

    public init(
        swiftLint: Bool = true,
        tests: Bool = true,
        fastlane: Bool = true,
        gitInit: Bool = true,
        keepProjectSpec: Bool = false,
        agentGuide: Bool = true
    ) {
        self.swiftLint = swiftLint
        self.tests = tests
        self.fastlane = fastlane
        self.gitInit = gitInit
        self.keepProjectSpec = keepProjectSpec
        self.agentGuide = agentGuide
    }

    /// Missing keys fall back to their defaults, so preferences saved by older versions still decode.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Extras()
        swiftLint = try container.decodeIfPresent(Bool.self, forKey: .swiftLint) ?? defaults.swiftLint
        tests = try container.decodeIfPresent(Bool.self, forKey: .tests) ?? defaults.tests
        fastlane = try container.decodeIfPresent(Bool.self, forKey: .fastlane) ?? defaults.fastlane
        gitInit = try container.decodeIfPresent(Bool.self, forKey: .gitInit) ?? defaults.gitInit
        keepProjectSpec = try container.decodeIfPresent(Bool.self, forKey: .keepProjectSpec) ?? defaults.keepProjectSpec
        agentGuide = try container.decodeIfPresent(Bool.self, forKey: .agentGuide) ?? defaults.agentGuide
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
