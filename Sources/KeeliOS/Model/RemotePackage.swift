import Foundation

/// A Swift package from a git repository, linked to the app target.
public struct RemotePackage: Identifiable, Hashable, Codable, Sendable {
    public enum Requirement: Hashable, Codable, Sendable {
        case upToNextMajor(String)
        case upToNextMinor(String)
        case exact(String)
        case branch(String)

        public var value: String {
            switch self {
            case let .upToNextMajor(value), let .upToNextMinor(value), let .exact(value), let .branch(value): value
            }
        }
    }

    public var id = UUID()
    /// Package identity used in the project, usually the last path component of the URL.
    public var name: String
    public var url: String
    public var requirement: Requirement
    public var products: [String]
    /// Extra `OTHER_LDFLAGS` the package needs, e.g. `-ObjC` for Firebase.
    public var linkerFlags: [String] = []

    public init(name: String, url: String, requirement: Requirement, products: [String], linkerFlags: [String] = []) {
        self.name = name
        self.url = url
        self.requirement = requirement
        self.products = products
        self.linkerFlags = linkerFlags
    }

    /// "https://github.com/Alamofire/Alamofire.git" → "Alamofire"
    public static func name(fromURL url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = trimmed.split(separator: "/").last.map(String.init) ?? trimmed
        return last.hasSuffix(".git") ? String(last.dropLast(4)) : last
    }

    /// The XcodeGen `packages:` entry.
    var specDictionary: [String: Any] {
        switch requirement {
        case let .upToNextMajor(version): ["url": url, "from": version]
        case let .upToNextMinor(version): ["url": url, "minorVersion": version]
        case let .exact(version): ["url": url, "exactVersion": version]
        case let .branch(branch): ["url": url, "branch": branch]
        }
    }
}
