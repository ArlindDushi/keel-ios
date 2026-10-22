import Foundation
import KeelCore

extension ProjectConfiguration {
    /// Flags and variables the templates in `Resources/Templates` can use.
    public func templateContext(date: Date = .now) -> TemplateContext {
        var flags: Set<String> = [uiFramework.rawValue, pattern.rawValue]
        if extras.tests { flags.insert("tests") }
        if extras.swiftLint { flags.insert("swiftlint") }
        if extras.fastlane { flags.insert("fastlane") }
        if extras.gitInit { flags.insert("git") }
        if deviceFamily == .universal { flags.insert("universal") }
        if !teamID.isEmpty { flags.insert("has_team") }
        for product in resolvedPackages.flatMap(\.products) {
            flags.insert("has_\(product.filter { $0.isLetter || $0.isNumber || $0 == "_" })")
            if product.hasPrefix("Firebase") { flags.insert("has_Firebase") }
        }

        let year = date.formatted(.dateTime.year())
        let environments = self.environments
        let production = productionEnvironment ?? environments.last
        let schemes = environments.map { $0.schemeName(appName: appName) }

        let variables: [String: String] = [
            "APP_NAME": appName,
            "DISPLAY_NAME": displayName,
            "BUNDLE_ID": bundleID,
            "ORGANIZATION": organizationName,
            "AUTHOR": authorName,
            "YEAR": year,
            "DATE": date.formatted(date: .numeric, time: .omitted),
            "DEPLOYMENT_TARGET": deploymentTarget,
            "TEAM_ID": teamID,
            "UI_FRAMEWORK": uiFramework.displayName,
            "PATTERN_NAME": pattern.displayName,
            "ENV_CASES": environments.map { "case \($0.caseName)" }.joined(separator: "\n"),
            "PRODUCTION_ENV_CASE": production?.caseName ?? "",
            "FIRST_SCHEME": schemes.first ?? appName,
            "ENV_TABLE": environments.map { environment in
                let bundle = bundleID + environment.bundleIDSuffix
                return "| \(environment.name) | `\(environment.schemeName(appName: appName))` | `\(bundle)` "
                    + "| \(displayName + environment.displayNameSuffix) | \(environment.apiBaseURL) |"
            }.joined(separator: "\n"),
            "PACKAGES_LIST": resolvedPackages.isEmpty
                ? "None yet — add them in Xcode under *File ▸ Add Package Dependencies…*."
                : resolvedPackages.map { "- [\($0.name)](\($0.url)): \($0.products.joined(separator: ", "))" }
                    .joined(separator: "\n"),
            "FASTLANE_LANES": environments.map(fastlaneLane).joined(separator: "\n\n"),
            "FASTLANE_LANE_LIST": environments.map { "- `bundle exec fastlane beta_\($0.caseName.lowercased())`" }
                .joined(separator: "\n")
        ]
        return TemplateContext(variables: variables, flags: flags)
    }

    private func fastlaneLane(_ environment: AppEnvironment) -> String {
        """
        desc "Builds the \(environment.name) app and uploads it to TestFlight"
        lane :beta_\(environment.caseName.lowercased()) do
          increment_build_number(build_number: latest_testflight_build_number(app_identifier: "\(bundleID + environment.bundleIDSuffix)") + 1)
          build_app(
            scheme: "\(environment.schemeName(appName: appName))",
            configuration: "\(environment.releaseConfigurationName)",
            export_method: "app-store"
          )
          upload_to_testflight(skip_waiting_for_build_processing: true)
        end
        """
    }

    /// Contents of `Configuration/<Environment>.xcconfig`.
    func xcconfig(for environment: AppEnvironment) -> String {
        // `//` starts a comment in xcconfig files, so URLs need the `$()` escape.
        let url = environment.apiBaseURL.replacingOccurrences(of: "//", with: "/$()/")
        return """
        // \(environment.name) environment, used by the "\(environment.schemeName(appName: appName))" scheme.
        // Values here are read by Info.plist and exposed in code through `AppEnvironment`.

        #include "Shared.xcconfig"

        APP_ENVIRONMENT = \(environment.caseName)
        BUNDLE_ID_SUFFIX = \(environment.bundleIDSuffix)
        APP_DISPLAY_NAME = \(displayName + environment.displayNameSuffix)
        API_BASE_URL = \(url)
        SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) \(environment.compilationCondition)

        """
    }
}
