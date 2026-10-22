import Foundation
import KeeliOS

/// Values remembered between launches.
@MainActor
enum Preferences {
    private static var defaults: UserDefaults { .standard }

    static var organizationName: String {
        get { defaults.string(forKey: "organizationName") ?? "" }
        set { defaults.set(newValue, forKey: "organizationName") }
    }

    static var bundleIDPrefix: String {
        get { defaults.string(forKey: "bundleIDPrefix") ?? "com.example" }
        set { defaults.set(newValue, forKey: "bundleIDPrefix") }
    }

    static var teamID: String {
        get { defaults.string(forKey: "teamID") ?? "" }
        set { defaults.set(newValue, forKey: "teamID") }
    }

    static var outputDirectory: URL {
        get {
            if let path = defaults.string(forKey: "outputDirectory"), FileManager.default.fileExists(atPath: path) {
                return URL(filePath: path, directoryHint: .isDirectory)
            }
            let developer = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Developer")
            return FileManager.default.fileExists(atPath: developer.path)
                ? developer
                : FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop")
        }
        set { defaults.set(newValue.path, forKey: "outputDirectory") }
    }

    static var extras: Extras {
        get {
            guard let data = defaults.data(forKey: "extras"),
                  let extras = try? JSONDecoder().decode(Extras.self, from: data) else { return Extras() }
            return extras
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "extras") }
    }

    static var openInXcode: Bool {
        get { defaults.object(forKey: "openInXcode") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "openInXcode") }
    }
}
