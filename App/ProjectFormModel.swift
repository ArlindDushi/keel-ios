import AppKit
import KeeliOS
import Observation

/// State of the form. Builds a `ProjectConfiguration` and runs the generator.
@MainActor
@Observable
final class ProjectFormModel {
    // MARK: General

    var appName = "" {
        didSet { appNameDidChange(from: oldValue) }
    }
    var displayName = ""
    var bundleID = ""
    var organizationName = Preferences.organizationName {
        didSet { Preferences.organizationName = organizationName }
    }
    var bundleIDPrefix = Preferences.bundleIDPrefix {
        didSet { bundleIDPrefixDidChange(from: oldValue) }
    }
    var authorName = NSFullUserName()
    var teamID = Preferences.teamID {
        didSet { Preferences.teamID = teamID }
    }
    var deploymentTarget = "17.0"
    var deviceFamily = DeviceFamily.iPhone
    var outputDirectory = Preferences.outputDirectory {
        didSet { Preferences.outputDirectory = outputDirectory }
    }

    // MARK: Environments

    var environments = AppEnvironment.defaults

    // MARK: Architecture

    var uiFramework = UIFramework.swiftUI {
        didSet { uiFrameworkDidChange() }
    }
    var pattern = ArchitecturePattern.mvvm

    // MARK: Packages

    let catalog: [SDKCatalogEntry]
    /// Selected catalog entries and the products picked for each.
    var selectedProducts: [SDKCatalogEntry.ID: Set<String>] = [:]
    var customPackages: [RemotePackage] = []

    // MARK: Extras

    var extras = Preferences.extras {
        didSet { Preferences.extras = extras }
    }
    var openInXcode = Preferences.openInXcode {
        didSet { Preferences.openInXcode = openInXcode }
    }

    // MARK: Generation

    enum Phase: Equatable {
        case idle
        case running(GenerationStep)
        case finished(projectFile: URL, warnings: [String])
        case failed(String)
    }

    var phase = Phase.idle

    // MARK: Issues

    /// Outlines the fields that need fixing; turned on from the "things to fix" button.
    var highlightsIssues = false
    var scrollRequest: ScrollRequest?
    var issueCursor = 0
    /// Set when the project folder exists and the user has to confirm replacing it.
    var pendingOverwrite: URL?

    init() {
        catalog = (try? SDKCatalog.load()) ?? []
    }

    // MARK: Derived

    var configuration: ProjectConfiguration {
        ProjectConfiguration(
            appName: appName.trimmingCharacters(in: .whitespaces),
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            bundleID: bundleID.trimmingCharacters(in: .whitespaces),
            organizationName: organizationName.trimmingCharacters(in: .whitespaces),
            authorName: authorName,
            teamID: teamID.trimmingCharacters(in: .whitespaces),
            deploymentTarget: deploymentTarget.trimmingCharacters(in: .whitespaces),
            deviceFamily: deviceFamily,
            environments: environments,
            uiFramework: uiFramework,
            pattern: pattern,
            packages: selectedPackages + customPackages,
            extras: extras,
            outputDirectory: outputDirectory
        )
    }

    var issues: [ValidationIssue] {
        ConfigurationValidator.issues(for: configuration)
    }

    func issues(for field: ValidationIssue.Field) -> [ValidationIssue] {
        issues.filter { $0.field == field }
    }

    var availableCatalog: [SDKCatalogEntry] {
        catalog.filter { $0.supports(uiFramework) }
    }

    /// Paths shown in the preview, including the project file.
    var plannedFiles: [String] {
        var configuration = configuration
        if configuration.appName.isEmpty { configuration.appName = "AppName" }
        let files = (try? Generator(configuration: configuration).plannedFiles()) ?? []
        return files + ["\(configuration.appName).xcodeproj"]
    }

    var isGenerating: Bool {
        if case .running = phase { return true }
        return false
    }

    // MARK: Packages

    func isSelected(_ entry: SDKCatalogEntry) -> Bool {
        selectedProducts[entry.id] != nil
    }

    func setSelected(_ selected: Bool, _ entry: SDKCatalogEntry) {
        selectedProducts[entry.id] = selected ? Set(entry.defaultProducts) : nil
    }

    func setProduct(_ product: String, selected: Bool, of entry: SDKCatalogEntry) {
        var products = selectedProducts[entry.id] ?? []
        if selected {
            products.insert(product)
        } else {
            products.remove(product)
        }
        selectedProducts[entry.id] = products
    }

    // MARK: Environments

    func addEnvironment() {
        let existing = Set(environments.map { $0.name.lowercased() })
        var name = "Staging"
        var index = 2
        while existing.contains(name.lowercased()) {
            name = "Staging\(index)"
            index += 1
        }
        let environment = AppEnvironment(name: name, apiBaseURL: "https://\(name.lowercased()).api.example.com")
        let productionIndex = environments.firstIndex(where: \.isProduction) ?? environments.endIndex
        environments.insert(environment, at: productionIndex)
    }

    func removeEnvironment(_ environment: AppEnvironment) {
        environments.removeAll { $0.id == environment.id }
        if !environments.isEmpty, !environments.contains(where: \.isProduction) {
            makeProduction(environments[environments.count - 1])
        }
    }

    func makeProduction(_ environment: AppEnvironment) {
        for index in environments.indices {
            let wasProduction = environments[index].isProduction
            let isProduction = environments[index].id == environment.id
            guard wasProduction != isProduction else { continue }
            var updated = environments[index]
            // Only replace suffixes the user hasn't customized.
            if updated.bundleIDSuffix == AppEnvironment.suggestedBundleIDSuffix(for: updated.name, isProduction: wasProduction) {
                updated.bundleIDSuffix = AppEnvironment.suggestedBundleIDSuffix(for: updated.name, isProduction: isProduction)
            }
            if updated.displayNameSuffix == AppEnvironment.suggestedDisplayNameSuffix(for: updated.name, isProduction: wasProduction) {
                updated.displayNameSuffix = AppEnvironment.suggestedDisplayNameSuffix(for: updated.name, isProduction: isProduction)
            }
            updated.isProduction = isProduction
            environments[index] = updated
        }
    }

    func rename(_ environment: AppEnvironment, to name: String) {
        guard let index = environments.firstIndex(where: { $0.id == environment.id }) else { return }
        var updated = environments[index]
        let oldName = updated.name
        let isProduction = updated.isProduction
        if updated.bundleIDSuffix == AppEnvironment.suggestedBundleIDSuffix(for: oldName, isProduction: isProduction) {
            updated.bundleIDSuffix = AppEnvironment.suggestedBundleIDSuffix(for: name, isProduction: isProduction)
        }
        if updated.displayNameSuffix == AppEnvironment.suggestedDisplayNameSuffix(for: oldName, isProduction: isProduction) {
            updated.displayNameSuffix = AppEnvironment.suggestedDisplayNameSuffix(for: name, isProduction: isProduction)
        }
        updated.name = name
        environments[index] = updated
    }

    // MARK: Generation

    func generate(overwrite: Bool = false) {
        let configuration = configuration
        if !overwrite, FileManager.default.fileExists(atPath: configuration.projectDirectory.path) {
            pendingOverwrite = configuration.projectDirectory
            return
        }
        pendingOverwrite = nil
        phase = .running(.validating)
        let openInXcode = openInXcode

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try Generator(configuration: configuration, overwrite: overwrite).generate { step in
                        Task { @MainActor in
                            if case .running = self.phase { self.phase = .running(step) }
                        }
                    }
                }.value
                phase = .finished(projectFile: result.projectFile, warnings: result.warnings)
                if openInXcode {
                    NSWorkspace.shared.open(result.projectFile)
                }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.message = "Choose where to create the project folder."
        panel.directoryURL = outputDirectory
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url
        }
    }
}

private extension ProjectFormModel {
    var selectedPackages: [RemotePackage] {
        availableCatalog.compactMap { entry in
            guard let products = selectedProducts[entry.id] else { return nil }
            return entry.package(products: Array(products))
        }
    }

    // MARK: Auto-filled fields

    func suggestedBundleID(prefix: String, appName: String) -> String {
        let name = appName.lowercased().filter { $0.isLetter || $0.isNumber }
        let prefix = prefix.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        return [prefix, name].filter { !$0.isEmpty }.joined(separator: ".")
    }

    func appNameDidChange(from oldValue: String) {
        if displayName.isEmpty || displayName == oldValue {
            displayName = appName
        }
        if bundleID.isEmpty || bundleID == suggestedBundleID(prefix: bundleIDPrefix, appName: oldValue) {
            bundleID = suggestedBundleID(prefix: bundleIDPrefix, appName: appName)
        }
    }

    func bundleIDPrefixDidChange(from oldValue: String) {
        Preferences.bundleIDPrefix = bundleIDPrefix
        if bundleID.isEmpty || bundleID == suggestedBundleID(prefix: oldValue, appName: appName) {
            bundleID = suggestedBundleID(prefix: bundleIDPrefix, appName: appName)
        }
    }

    func uiFrameworkDidChange() {
        if !pattern.supports(uiFramework),
           let replacement = ArchitecturePattern.allCases.first(where: { $0.supports(uiFramework) }) {
            pattern = pattern == .tca ? .mvvm : replacement
        }
        for entry in catalog where !entry.supports(uiFramework) {
            selectedProducts[entry.id] = nil
        }
    }
}
