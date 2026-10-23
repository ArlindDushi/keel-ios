import Foundation
import Testing
@testable import KeeliOS

struct ConfigurationValidatorTests {
    @Test func fixtureIsValid() {
        #expect(issues { _ in }.isEmpty)
    }

    @Test(arguments: ["", "1App", "My App", "class"])
    func rejectsInvalidAppNames(name: String) {
        #expect(issues { $0.appName = name }.contains { $0.field == .appName })
    }

    @Test(arguments: ["demo", "com.", "com..demo", "com.demo app"])
    func rejectsInvalidBundleIDs(bundleID: String) {
        #expect(issues { $0.bundleID = bundleID }.contains { $0.field == .bundleID })
    }

    @Test func requiresExactlyOneProduction() {
        #expect(issues { $0.environments[0].isProduction = true }.contains { $0.field == .environments })
        #expect(issues { $0.environments[2].isProduction = false }.contains { $0.field == .environments })
        #expect(issues { $0.environments = [] }.contains { $0.field == .environments })
    }

    @Test func rejectsDuplicateEnvironmentsAndBadURLs() {
        let duplicates = issues { $0.environments[1].name = "dev" }
        #expect(duplicates.contains { $0.message.contains("more than one") })

        let configuration = ProjectConfiguration.fixture()
        var badURL = configuration
        badURL.environments[0].apiBaseURL = "not a url"
        let id = configuration.environments[0].id
        #expect(ConfigurationValidator.issues(for: badURL).contains { $0.field == .environment(id) })
    }

    @Test func rejectsUnsupportedPatternCombination() {
        #expect(issues { $0.pattern = .tca; $0.uiFramework = .uiKit }.contains { $0.field == .pattern })
        #expect(issues { $0.pattern = .mvc; $0.uiFramework = .swiftUI }.contains { $0.field == .pattern })
    }

    @Test func rejectsOldDeploymentTargets() {
        #expect(issues { $0.deploymentTarget = "16.0" }.contains { $0.field == .deploymentTarget })
        #expect(issues { $0.deploymentTarget = "latest" }.contains { $0.field == .deploymentTarget })
    }

    @Test func rejectsPackagesWithoutProducts() {
        let package = RemotePackage(name: "Foo", url: "https://github.com/a/Foo", requirement: .upToNextMajor("1.0.0"), products: [])
        #expect(issues { $0.packages = [package] }.contains { $0.field == .package(package.id) })
    }
}

private extension ConfigurationValidatorTests {
    func issues(_ change: (inout ProjectConfiguration) -> Void) -> [ValidationIssue] {
        var configuration = ProjectConfiguration.fixture()
        change(&configuration)
        return ConfigurationValidator.issues(for: configuration)
    }
}
