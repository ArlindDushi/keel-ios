import KeeliOS
import SwiftUI

struct CustomPackageSheet: View {
    @Environment(ProjectFormModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    enum Rule: String, CaseIterable, Identifiable {
        case upToNextMajor = "Up to Next Major"
        case upToNextMinor = "Up to Next Minor"
        case exact = "Exact Version"
        case branch = "Branch"

        var id: String { rawValue }
    }

    @State private var url = ""
    @State private var rule = Rule.upToNextMajor
    @State private var version = "1.0.0"
    @State private var products = ""
    @State private var editedProducts = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section {
                    TextField("Repository URL", text: $url, prompt: Text("https://github.com/owner/package"))
                        .onChange(of: url) {
                            if !editedProducts { products = RemotePackage.name(fromURL: url) }
                        }
                    Picker("Dependency rule", selection: $rule) {
                        ForEach(Rule.allCases) { Text($0.rawValue).tag($0) }
                    }
                    TextField(rule == .branch ? "Branch" : "Version", text: $version, prompt: Text(rule == .branch ? "main" : "1.0.0"))
                    TextField("Products", text: Binding(get: { products }, set: { products = $0; editedProducts = true }), prompt: Text("Comma separated"))
                } footer: {
                    Text("Products are the libraries the package exposes, as listed in its Package.swift.")
                        .foregroundStyle(.secondary)
                }
                IssueText(issues: issues)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add Package") {
                    model.customPackages.append(package)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(url.isEmpty || !issues.isEmpty)
            }
            .padding()
        }
        .frame(width: 480)
    }

    private var package: RemotePackage {
        let value = version.trimmingCharacters(in: .whitespaces)
        let requirement: RemotePackage.Requirement = switch rule {
        case .upToNextMajor: .upToNextMajor(value)
        case .upToNextMinor: .upToNextMinor(value)
        case .exact: .exact(value)
        case .branch: .branch(value)
        }
        return RemotePackage(
            name: RemotePackage.name(fromURL: url),
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            requirement: requirement,
            products: products.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        )
    }

    private var issues: [ValidationIssue] {
        guard !url.isEmpty else { return [] }
        let existing = model.configuration.resolvedPackages
        return ConfigurationValidator.packageIssues(existing + [package]).filter { $0.field == .package(package.id) }
    }
}
