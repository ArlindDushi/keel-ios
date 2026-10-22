import Foundation
import KeelCore
import PathKit
import ProjectSpec
import XcodeGenKit

public enum GenerationStep: Int, CaseIterable, Sendable {
    case validating
    case copyingTemplates
    case writingConfigurations
    case generatingProject
    case initializingGit

    public var title: String {
        switch self {
        case .validating: "Validating"
        case .copyingTemplates: "Creating files"
        case .writingConfigurations: "Writing environment configurations"
        case .generatingProject: "Generating Xcode project"
        case .initializingGit: "Initializing git repository"
        }
    }
}

public struct GenerationResult: Sendable {
    public let projectDirectory: URL
    public let projectFile: URL
    /// Non-fatal problems, e.g. git couldn't commit.
    public let warnings: [String]
}

public enum GenerationError: LocalizedError {
    case invalidConfiguration([ValidationIssue])
    case destinationExists(URL)
    case template(path: String, message: String)
    case projectGeneration(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidConfiguration(issues):
            issues.map(\.message).joined(separator: "\n")
        case let .destinationExists(url):
            "“\(url.lastPathComponent)” already exists in \(url.deletingLastPathComponent().path)."
        case let .template(path, message):
            "Couldn't render \(path): \(message)"
        case let .projectGeneration(message):
            "XcodeGen couldn't generate the project: \(message)"
        }
    }
}

public struct Generator: Sendable {
    public let configuration: ProjectConfiguration
    /// Replace the project folder when it already exists.
    public var overwrite: Bool
    public var date: Date

    public init(configuration: ProjectConfiguration, overwrite: Bool = false, date: Date = .now) {
        self.configuration = configuration
        self.overwrite = overwrite
        self.date = date
    }

    /// Relative paths of every file that will be generated (without the .xcodeproj), for previews.
    public func plannedFiles() throws -> [String] {
        let context = configuration.templateContext(date: date)
        let templateFiles = try TemplateTree.trees(for: configuration.pattern, framework: configuration.uiFramework)
            .flatMap { try $0.files(context: context, appName: configuration.appName) }
            .map(\.destination)
        let xcconfigs = configuration.environments.map { "Configuration/\($0.xcconfigFileName)" }
        let spec = configuration.extras.keepProjectSpec ? ["project.yml"] : []
        return (templateFiles + xcconfigs + spec).uniqued().sorted()
    }

    @discardableResult
    public func generate(progress: @Sendable (GenerationStep) -> Void = { _ in }) throws -> GenerationResult {
        progress(.validating)
        let issues = ConfigurationValidator.issues(for: configuration)
        guard issues.isEmpty else { throw GenerationError.invalidConfiguration(issues) }

        let fileManager = FileManager.default
        let directory = configuration.projectDirectory
        if fileManager.fileExists(atPath: directory.path) {
            guard overwrite else { throw GenerationError.destinationExists(directory) }
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        do {
            var warnings: [String] = []
            progress(.copyingTemplates)
            try copyTemplates(to: directory)

            progress(.writingConfigurations)
            for environment in configuration.environments {
                try write(configuration.xcconfig(for: environment), to: directory.appending(path: "Configuration/\(environment.xcconfigFileName)"))
            }

            progress(.generatingProject)
            try generateProject(in: directory)

            if configuration.extras.gitInit {
                progress(.initializingGit)
                do {
                    try GitInitializer.initialize(at: directory)
                } catch {
                    warnings.append(error.localizedDescription)
                }
            }
            return GenerationResult(projectDirectory: directory, projectFile: configuration.projectFileURL, warnings: warnings)
        } catch {
            try? fileManager.removeItem(at: directory)
            throw error
        }
    }

    // MARK: - Steps

    private func copyTemplates(to directory: URL) throws {
        let context = configuration.templateContext(date: date)
        let renderer = TemplateRenderer(context: context)
        let testTargets: Set<String> = ["\(configuration.appName)Tests", "\(configuration.appName)UITests"]

        for tree in try TemplateTree.trees(for: configuration.pattern, framework: configuration.uiFramework) {
            for file in try tree.files(context: context, appName: configuration.appName) {
                let destination = directory.appending(path: file.destination)
                let data = try Data(contentsOf: file.source)
                guard let template = String(data: data, encoding: .utf8) else {
                    try write(data, to: destination)
                    continue
                }
                var contents: String
                do {
                    contents = try renderer.render(template)
                } catch {
                    throw GenerationError.template(path: file.destination, message: error.localizedDescription)
                }
                if destination.pathExtension == "swift" {
                    let firstComponent = String(file.destination.split(separator: "/").first ?? "")
                    contents = FileHeader.swift(
                        fileName: destination.lastPathComponent,
                        targetName: testTargets.contains(firstComponent) ? firstComponent : configuration.appName,
                        author: configuration.authorName,
                        organization: configuration.organizationName,
                        date: date
                    ) + contents.trimmingLeadingNewlines()
                }
                try write(contents, to: destination)
            }
        }
        try makeExecutable(directory.appending(path: "Scripts/swiftlint.sh"))
    }

    /// XcodeGen isn't safe to run concurrently, so generations are serialized.
    private static let xcodeGenLock = NSLock()

    private func generateProject(in directory: URL) throws {
        let basePath = Path(directory.path)
        let builder = SpecBuilder(configuration: configuration)
        do {
            try Self.xcodeGenLock.withLock {
                let project = try builder.project(basePath: basePath)
                try project.validate()
                let xcodeProject = try ProjectGenerator(project: project)
                    .generateXcodeProject(in: basePath, userName: NSUserName())
                let projectPath = basePath + "\(configuration.appName).xcodeproj"
                try FileWriter(project: project).writeXcodeProject(xcodeProject, to: projectPath)
            }
        } catch {
            throw GenerationError.projectGeneration(String(describing: error))
        }

        try write(
            FileHeader.templateMacrosPlist(organization: configuration.organizationName),
            to: configuration.projectFileURL.appending(path: "xcshareddata/IDETemplateMacros.plist")
        )
        if configuration.extras.keepProjectSpec {
            try write(builder.yaml(), to: directory.appending(path: "project.yml"))
        }
    }

    // MARK: - Files

    private func write(_ string: String, to url: URL) throws {
        try write(Data(string.utf8), to: url)
    }

    private func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    private func makeExecutable(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }
}

private extension String {
    func trimmingLeadingNewlines() -> String {
        String(drop(while: \.isNewline))
    }
}
