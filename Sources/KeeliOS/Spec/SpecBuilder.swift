import Foundation
import KeelCore
import PathKit
import ProjectSpec
import Yams

/// Builds the XcodeGen spec for a configuration. The dictionary mirrors `project.yml`
/// one-to-one, so the XcodeGen docs apply: https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md
public struct SpecBuilder: Sendable {
    public let configuration: ProjectConfiguration

    public init(configuration: ProjectConfiguration) {
        self.configuration = configuration
    }

    var appName: String { configuration.appName }
    var unitTestsName: String { "\(appName)Tests" }
    var uiTestsName: String { "\(appName)UITests" }

    public func dictionary() -> [String: Any] {
        var spec: [String: Any] = [
            "name": appName,
            "options": [
                "deploymentTarget": ["iOS": configuration.deploymentTarget],
                "developmentLanguage": "en",
                "generateEmptyDirectories": true,
                "groupSortPosition": "top"
            ],
            "configs": configs(),
            "settings": ["base": projectSettings()],
            "targets": targets(),
            "schemes": schemes()
        ]
        let packages = configuration.resolvedPackages
        if !packages.isEmpty {
            spec["packages"] = Dictionary(uniqueKeysWithValues: packages.map { ($0.name, $0.specDictionary) })
        }
        return spec
    }

    public func project(basePath: Path) throws -> Project {
        try Project(basePath: basePath, jsonDictionary: dictionary())
    }

    public func yaml() throws -> String {
        "# Regenerate the project with: xcodegen generate\n" + (try Yams.dump(object: dictionary(), sortKeys: true))
    }

    // MARK: - Sections

    private func configs() -> [String: String] {
        var configs: [String: String] = [:]
        for environment in configuration.environments {
            configs[environment.debugConfigurationName] = "debug"
            configs[environment.releaseConfigurationName] = "release"
        }
        return configs
    }

    private func projectSettings() -> [String: Any] {
        var settings: [String: Any] = [
            "SWIFT_VERSION": "6.0",
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "CODE_SIGN_STYLE": "Automatic",
            "ENABLE_USER_SCRIPT_SANDBOXING": configuration.extras.swiftLint ? "NO" : "YES",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            "SWIFT_EMIT_LOC_STRINGS": "YES"
        ]
        if !configuration.teamID.isEmpty {
            settings["DEVELOPMENT_TEAM"] = configuration.teamID
        }
        return settings
    }

    private func targets() -> [String: Any] {
        var targets: [String: Any] = [appName: appTarget()]
        if configuration.extras.tests {
            targets[unitTestsName] = testTarget(type: "bundle.unit-test", name: unitTestsName, suffix: "tests")
            targets[uiTestsName] = testTarget(type: "bundle.ui-testing", name: uiTestsName, suffix: "uitests")
        }
        return targets
    }

    private func appTarget() -> [String: Any] {
        let packages = configuration.resolvedPackages
        var settings: [String: Any] = [
            "INFOPLIST_FILE": "\(appName)/Resources/Info.plist",
            "GENERATE_INFOPLIST_FILE": "YES",
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "TARGETED_DEVICE_FAMILY": configuration.deviceFamily.targetedDeviceFamily,
            "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad":
                "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown "
                + "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        ]
        if configuration.uiFramework == .swiftUI {
            settings["INFOPLIST_KEY_UIApplicationSceneManifest_Generation"] = "YES"
        }
        let linkerFlags = packages.flatMap(\.linkerFlags).uniqued()
        if !linkerFlags.isEmpty {
            settings["OTHER_LDFLAGS"] = (["$(inherited)"] + linkerFlags).joined(separator: " ")
        }

        var configFiles: [String: String] = [:]
        for environment in configuration.environments {
            let path = "Configuration/\(environment.xcconfigFileName)"
            configFiles[environment.debugConfigurationName] = path
            configFiles[environment.releaseConfigurationName] = path
        }

        var target: [String: Any] = [
            "type": "application",
            "platform": "iOS",
            "sources": [["path": appName, "excludes": ["**/.gitkeep"]]],
            "configFiles": configFiles,
            "settings": ["base": settings],
            "dependencies": packages.flatMap { package in
                package.products.map { ["package": package.name, "product": $0] }
            }
        ]
        if configuration.extras.swiftLint {
            target["preBuildScripts"] = [[
                "name": "SwiftLint",
                "path": "Scripts/swiftlint.sh",
                "basedOnDependencyAnalysis": false
            ]]
        }
        return target
    }

    private func testTarget(type: String, name: String, suffix: String) -> [String: Any] {
        [
            "type": type,
            "platform": "iOS",
            "sources": [["path": name, "excludes": ["**/.gitkeep"]]],
            "dependencies": [["target": appName]],
            "settings": ["base": [
                "GENERATE_INFOPLIST_FILE": "YES",
                "PRODUCT_BUNDLE_IDENTIFIER": "\(configuration.bundleID).\(suffix)",
                "TARGETED_DEVICE_FAMILY": configuration.deviceFamily.targetedDeviceFamily
            ]]
        ]
    }

    private func schemes() -> [String: Any] {
        var schemes: [String: Any] = [:]
        for environment in configuration.environments {
            let debug = environment.debugConfigurationName
            let release = environment.releaseConfigurationName
            var scheme: [String: Any] = [
                "build": ["targets": [appName: "all"]],
                "run": ["config": debug],
                "profile": ["config": release],
                "analyze": ["config": debug],
                "archive": ["config": release]
            ]
            if configuration.extras.tests {
                scheme["test"] = [
                    "config": debug,
                    "gatherCoverageData": true,
                    "coverageTargets": [appName],
                    "targets": [unitTestsName, uiTestsName]
                ]
            }
            schemes[environment.schemeName(appName: appName)] = scheme
        }
        return schemes
    }
}
