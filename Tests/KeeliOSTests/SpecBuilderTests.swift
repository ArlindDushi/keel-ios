import Foundation
import Testing
@testable import KeeliOS

struct SpecBuilderTests {
    @Test func createsConfigsAndSchemesPerEnvironment() throws {
        let spec = SpecBuilder(configuration: .fixture()).dictionary()

        let configs = try #require(spec["configs"] as? [String: String])
        #expect(configs == [
            "Dev Debug": "debug", "Dev Release": "release",
            "Staging Debug": "debug", "Staging Release": "release",
            "Production Debug": "debug", "Production Release": "release"
        ])
        let schemes = try #require(spec["schemes"] as? [String: Any])
        #expect(Set(schemes.keys) == ["Demo Dev", "Demo Staging", "Demo Production"])
    }

    @Test func linksPackagesAndAddsRequiredOnes() throws {
        let alamofire = RemotePackage(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire", requirement: .exact("5.12.0"), products: ["Alamofire"])
        let spec = SpecBuilder(configuration: .fixture(pattern: .tca, packages: [alamofire])).dictionary()

        let packages = try #require(spec["packages"] as? [String: [String: String]])
        #expect(packages["Alamofire"] == ["url": "https://github.com/Alamofire/Alamofire", "exactVersion": "5.12.0"])
        #expect(packages["swift-composable-architecture"] != nil)

        let targets = try #require(spec["targets"] as? [String: Any])
        let app = try #require(targets["Demo"] as? [String: Any])
        let dependencies = try #require(app["dependencies"] as? [[String: String]])
        #expect(dependencies.contains(["package": "Alamofire", "product": "Alamofire"]))
        #expect(dependencies.contains(["package": "swift-composable-architecture", "product": "ComposableArchitecture"]))
    }

    @Test func leavesOutTestTargetsWhenDisabled() throws {
        let spec = SpecBuilder(configuration: .fixture(extras: Extras(tests: false, gitInit: false))).dictionary()
        let targets = try #require(spec["targets"] as? [String: Any])
        #expect(Set(targets.keys) == ["Demo"])
    }

    @Test func dumpsLoadableYAML() throws {
        let yaml = try SpecBuilder(configuration: .fixture()).yaml()
        #expect(yaml.contains("Demo Dev:"))
    }
}
