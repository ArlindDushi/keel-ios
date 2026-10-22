import Foundation
import Testing
@testable import KeeliOS

struct GeneratorTests {
    static let combinations: [(ArchitecturePattern, UIFramework)] = ArchitecturePattern.allCases.flatMap { pattern in
        pattern.supportedFrameworks.map { (pattern, $0) }
    }

    @Test(arguments: combinations)
    func generatesProject(pattern: ArchitecturePattern, framework: UIFramework) throws {
        let output = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let configuration = ProjectConfiguration.fixture(pattern: pattern, framework: framework, outputDirectory: output)

        let result = try Generator(configuration: configuration).generate()

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: result.projectFile.appending(path: "project.pbxproj").path))
        for environment in configuration.environments {
            let scheme = "xcshareddata/xcschemes/\(environment.schemeName(appName: "Demo")).xcscheme"
            #expect(fileManager.fileExists(atPath: result.projectFile.appending(path: scheme).path))
            #expect(fileManager.fileExists(atPath: result.projectDirectory.appending(path: "Configuration/\(environment.xcconfigFileName)").path))
        }
        #expect(fileManager.fileExists(atPath: result.projectFile.appending(path: "xcshareddata/IDETemplateMacros.plist").path))

        let planned = try Generator(configuration: configuration).plannedFiles()
        for file in planned {
            #expect(fileManager.fileExists(atPath: result.projectDirectory.appending(path: file).path), "\(file) is missing")
        }
        #expect(planned.contains("Demo/Core/Environment/AppEnvironment.swift"))

        let environment = try String(contentsOf: result.projectDirectory.appending(path: "Demo/Core/Environment/AppEnvironment.swift"), encoding: .utf8)
        #expect(environment.hasPrefix("//\n//  AppEnvironment.swift\n//  Demo\n"))
        #expect(environment.contains("    case dev\n    case staging\n    case production\n"))
    }

    @Test func refusesToOverwrite() throws {
        let output = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let configuration = ProjectConfiguration.fixture(outputDirectory: output)
        try Generator(configuration: configuration).generate()

        #expect(throws: GenerationError.self) { try Generator(configuration: configuration).generate() }
        try Generator(configuration: configuration, overwrite: true).generate()
    }

    @Test func optionalModulesAreLeftOut() throws {
        let configuration = ProjectConfiguration.fixture(
            extras: Extras(swiftLint: false, tests: false, fastlane: false, gitInit: false)
        )
        let files = try Generator(configuration: configuration).plannedFiles()
        #expect(!files.contains { $0.hasPrefix("DemoTests") || $0.hasPrefix("DemoUITests") })
        #expect(!files.contains { $0.hasPrefix("fastlane") || $0 == "Gemfile" })
        #expect(!files.contains(".swiftlint.yml"))
        #expect(files.contains(".gitignore"))
    }

    @Test func xcconfigEscapesURLs() {
        let configuration = ProjectConfiguration.fixture()
        let xcconfig = configuration.xcconfig(for: configuration.environments[0])
        #expect(xcconfig.contains("API_BASE_URL = https:/$()/dev.api.example.com"))
        #expect(xcconfig.contains("BUNDLE_ID_SUFFIX = .dev"))
        #expect(xcconfig.contains("APP_DISPLAY_NAME = Demo App Dev"))
    }

    /// Builds every generated combination with xcodebuild. Slow and needs the network for packages,
    /// so it only runs with `KEEL_E2E=1 swift test`.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["KEEL_E2E"] == "1"), arguments: combinations)
    func generatedProjectBuilds(pattern: ArchitecturePattern, framework: UIFramework) throws {
        let output = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: output) }
        let configuration = ProjectConfiguration.fixture(
            pattern: pattern,
            framework: framework,
            extras: Extras(swiftLint: false, tests: true, fastlane: true, gitInit: false),
            outputDirectory: output
        )
        let result = try Generator(configuration: configuration).generate()

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/xcrun")
        process.arguments = [
            "xcodebuild", "build-for-testing",
            "-project", result.projectFile.path,
            "-scheme", "Demo Dev",
            "-destination", "generic/platform=iOS Simulator",
            "-derivedDataPath", output.appending(path: "DerivedData").path,
            "-skipMacroValidation",
            "CODE_SIGNING_ALLOWED=NO"
        ]
        let log = output.appending(path: "build.log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        process.waitUntilExit()
        try handle.close()

        if process.terminationStatus != 0 {
            let output = try String(contentsOf: log, encoding: .utf8)
            let errors = output.split(separator: "\n").filter { $0.contains("error:") }.prefix(20).joined(separator: "\n")
            Issue.record("xcodebuild failed for \(pattern) / \(framework):\n\(errors)")
        }
    }
}

/// Writes every combination into `$KEEL_SAMPLES` for manual inspection:
/// `KEEL_SAMPLES=/tmp/samples swift test --filter writeSamples`
@Test(.enabled(if: ProcessInfo.processInfo.environment["KEEL_SAMPLES"] != nil), arguments: GeneratorTests.combinations)
func writeSamples(pattern: ArchitecturePattern, framework: UIFramework) throws {
    let root = URL(filePath: ProcessInfo.processInfo.environment["KEEL_SAMPLES"] ?? "")
        .appending(path: "\(pattern.rawValue)-\(framework.rawValue)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    var configuration = ProjectConfiguration.fixture(pattern: pattern, framework: framework, outputDirectory: root)
    configuration.packages = [
        RemotePackage(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire", requirement: .upToNextMajor("5.12.0"), products: ["Alamofire"])
    ]
    configuration.extras.keepProjectSpec = true
    try Generator(configuration: configuration, overwrite: true).generate()
}
