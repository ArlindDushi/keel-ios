import Foundation
@testable import KeeliOS

extension ProjectConfiguration {
    static func fixture(
        pattern: ArchitecturePattern = .mvvm,
        framework: UIFramework = .swiftUI,
        packages: [RemotePackage] = [],
        extras: Extras = Extras(gitInit: false),
        outputDirectory: URL = FileManager.default.temporaryDirectory
    ) -> ProjectConfiguration {
        ProjectConfiguration(
            appName: "Demo",
            displayName: "Demo App",
            bundleID: "com.example.demo",
            organizationName: "Example Inc.",
            authorName: "Test Author",
            uiFramework: framework,
            pattern: pattern,
            packages: packages,
            extras: extras,
            outputDirectory: outputDirectory
        )
    }
}

func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "KeelTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
