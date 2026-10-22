import Foundation

/// Everything the user picked in the form — the single input of `Generator`.
public struct ProjectConfiguration: Hashable, Sendable {
    public var appName: String
    public var displayName: String
    public var bundleID: String
    public var organizationName: String
    /// Name used in file headers ("Created by …").
    public var authorName: String
    public var teamID: String
    public var deploymentTarget: String
    public var deviceFamily: DeviceFamily
    public var environments: [AppEnvironment]
    public var uiFramework: UIFramework
    public var pattern: ArchitecturePattern
    /// Packages picked from the catalog and custom ones, in the order they were added.
    public var packages: [RemotePackage]
    public var extras: Extras
    /// Parent folder; the project is created in `outputDirectory/appName`.
    public var outputDirectory: URL

    public init(
        appName: String,
        displayName: String? = nil,
        bundleID: String,
        organizationName: String,
        authorName: String = NSFullUserName(),
        teamID: String = "",
        deploymentTarget: String = "17.0",
        deviceFamily: DeviceFamily = .iPhone,
        environments: [AppEnvironment] = AppEnvironment.defaults,
        uiFramework: UIFramework = .swiftUI,
        pattern: ArchitecturePattern = .mvvm,
        packages: [RemotePackage] = [],
        extras: Extras = Extras(),
        outputDirectory: URL
    ) {
        self.appName = appName
        self.displayName = displayName ?? appName
        self.bundleID = bundleID
        self.organizationName = organizationName
        self.authorName = authorName
        self.teamID = teamID
        self.deploymentTarget = deploymentTarget
        self.deviceFamily = deviceFamily
        self.environments = environments
        self.uiFramework = uiFramework
        self.pattern = pattern
        self.packages = packages
        self.extras = extras
        self.outputDirectory = outputDirectory
    }

    public var projectDirectory: URL {
        outputDirectory.appending(path: appName, directoryHint: .isDirectory)
    }

    public var projectFileURL: URL {
        projectDirectory.appending(path: "\(appName).xcodeproj", directoryHint: .isDirectory)
    }

    /// The user's packages plus the ones the pattern requires, without duplicates.
    public var resolvedPackages: [RemotePackage] {
        var result = packages
        for required in pattern.requiredPackages
        where !result.contains(where: { $0.url.lowercased() == required.url.lowercased() }) {
            result.append(required)
        }
        return result
    }

    public var productionEnvironment: AppEnvironment? {
        environments.first(where: \.isProduction)
    }
}
