import Foundation

public struct ValidationIssue: Hashable, Sendable, Identifiable {
    public enum Field: Hashable, Sendable {
        case appName, displayName, bundleID, organizationName, teamID, deploymentTarget
        case environments, environment(UUID)
        case pattern, packages, package(UUID), outputDirectory
    }

    public let field: Field
    public let message: String
    public var id: String { "\(field)-\(message)" }
}

public enum ConfigurationValidator {
    public static let minimumDeploymentTarget = 17.0

    private static let reservedNames: Set<String> = [
        "debug", "release", "test", "tests", "default", "self", "super", "class", "struct", "enum",
        "protocol", "extension", "func", "var", "let", "case", "switch", "if", "else", "for", "while",
        "return", "import", "true", "false", "nil", "init", "public", "private", "internal", "static",
        "swift", "swiftui", "uikit", "foundation", "combine"
    ]

    public static func issues(for configuration: ProjectConfiguration, checkFileSystem: Bool = true) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        func add(_ field: ValidationIssue.Field, _ message: String) {
            issues.append(ValidationIssue(field: field, message: message))
        }

        let appName = configuration.appName
        if appName.isEmpty {
            add(.appName, "Enter an app name.")
        } else if appName.wholeMatch(of: /[A-Za-z][A-Za-z0-9]*/) == nil {
            add(.appName, "The app name must start with a letter and contain only letters and digits.")
        } else if reservedNames.contains(appName.lowercased()) {
            add(.appName, "“\(appName)” can't be used as an app name.")
        }

        let displayName = configuration.displayName.trimmingCharacters(in: .whitespaces)
        if displayName.isEmpty {
            add(.displayName, "Enter a display name.")
        } else if displayName.contains(where: { "\"$\\\n".contains($0) }) {
            add(.displayName, "The display name can't contain quotes, $, backslashes or line breaks.")
        }

        if configuration.bundleID.wholeMatch(of: /[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+/) == nil {
            add(.bundleID, "Use a reverse-DNS bundle identifier such as com.company.app.")
        }

        if configuration.organizationName.trimmingCharacters(in: .whitespaces).isEmpty {
            add(.organizationName, "Enter an organization name; it's used in file headers.")
        }

        if !configuration.teamID.isEmpty, configuration.teamID.wholeMatch(of: /[A-Z0-9]{10}/) == nil {
            add(.teamID, "A team ID has 10 uppercase letters or digits.")
        }

        if let version = Double(configuration.deploymentTarget),
           configuration.deploymentTarget.wholeMatch(of: /\d+(\.\d+)?/) != nil {
            if version < minimumDeploymentTarget {
                add(.deploymentTarget, "The templates need iOS \(Int(minimumDeploymentTarget)) or later.")
            }
        } else {
            add(.deploymentTarget, "Use a version such as 17.0.")
        }

        issues += environmentIssues(configuration.environments)

        if !configuration.pattern.supports(configuration.uiFramework) {
            add(.pattern, "\(configuration.pattern.displayName) isn't available for \(configuration.uiFramework.displayName).")
        }

        issues += packageIssues(configuration.resolvedPackages)

        if checkFileSystem {
            var isDirectory: ObjCBool = false
            if !FileManager.default.fileExists(atPath: configuration.outputDirectory.path, isDirectory: &isDirectory)
                || !isDirectory.boolValue {
                add(.outputDirectory, "Choose an existing output folder.")
            }
        }
        return issues
    }

    public static func environmentIssues(_ environments: [AppEnvironment]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if environments.isEmpty {
            issues.append(ValidationIssue(field: .environments, message: "Add at least one environment."))
        }
        let productionCount = environments.count(where: \.isProduction)
        if !environments.isEmpty, productionCount != 1 {
            issues.append(ValidationIssue(field: .environments, message: "Mark exactly one environment as production."))
        }

        var seenNames: Set<String> = []
        var seenSuffixes: Set<String> = []
        for environment in environments {
            func add(_ message: String) {
                issues.append(ValidationIssue(field: .environment(environment.id), message: message))
            }
            let name = environment.name
            if name.wholeMatch(of: /[A-Za-z][A-Za-z0-9]*/) == nil {
                add("Environment names must start with a letter and contain only letters and digits.")
            } else if reservedNames.contains(name.lowercased()) {
                add("“\(name)” can't be used as an environment name.")
            } else if !seenNames.insert(name.lowercased()).inserted {
                add("There's more than one environment named “\(name)”.")
            }

            if !environment.bundleIDSuffix.isEmpty, environment.bundleIDSuffix.wholeMatch(of: /(\.[A-Za-z0-9-]+)+/) == nil {
                add("The bundle ID suffix of “\(name)” must look like .\(name.lowercased()).")
            } else if !seenSuffixes.insert(environment.bundleIDSuffix).inserted {
                add("“\(name)” has the same bundle ID suffix as another environment.")
            }

            if environment.displayNameSuffix.contains(where: { "\"$\\\n".contains($0) }) {
                add("The display name suffix of “\(name)” can't contain quotes, $, backslashes or line breaks.")
            }

            if let url = URL(string: environment.apiBaseURL), ["http", "https"].contains(url.scheme), url.host() != nil,
               !environment.apiBaseURL.contains(where: \.isWhitespace) {
                // valid
            } else {
                add("The API base URL of “\(name)” must be an http(s) URL.")
            }
        }
        return issues
    }

    public static func packageIssues(_ packages: [RemotePackage]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        var seenNames: Set<String> = []
        for package in packages {
            func add(_ message: String) {
                issues.append(ValidationIssue(field: .package(package.id), message: message))
            }
            if let url = URL(string: package.url), url.scheme != nil, url.host() != nil || url.scheme == "file" {
                // valid
            } else {
                add("“\(package.url)” isn't a valid package URL.")
            }
            if package.name.isEmpty {
                add("The package needs a name.")
            } else if !seenNames.insert(package.name.lowercased()).inserted {
                add("The package “\(package.name)” was added twice.")
            }
            if package.requirement.value.trimmingCharacters(in: .whitespaces).isEmpty {
                add("Enter a version or branch for “\(package.name)”.")
            }
            if package.products.isEmpty || package.products.contains(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                add("Choose at least one product of “\(package.name)”.")
            }
        }
        return issues
    }
}
