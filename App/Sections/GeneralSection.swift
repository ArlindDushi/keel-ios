import KeeliOS
import SwiftUI

struct GeneralSection: View {
    @Environment(ProjectFormModel.self) private var model

    private let deploymentTargets = ["17.0", "18.0", "26.0", "27.0"]

    var body: some View {
        @Bindable var model = model
        Section("Project") {
            field("App name", text: $model.appName, prompt: "MyApp", field: .appName, hideWhenEmpty: true)
            field("Display name", text: $model.displayName, prompt: "My App", field: .displayName, hideWhenEmpty: true)
            TextField("Bundle ID prefix", text: $model.bundleIDPrefix, prompt: Text("com.company"))
            field("Bundle ID", text: $model.bundleID, prompt: "com.company.myapp", field: .bundleID, hideWhenEmpty: true)
        }

        Section("Ownership") {
            field("Organization", text: $model.organizationName, prompt: "Company Inc", field: .organizationName, hideWhenEmpty: true) {
                HeaderCaption(
                    explanation: "Copyright holder in the header of every generated file, and of files you add later in Xcode.",
                    example: "Copyright © \(Date.now.formatted(.dateTime.year())) \(copyrightHolder). All rights reserved."
                )
            }
            VStack(alignment: .leading, spacing: 4) {
                TextField("Author", text: $model.authorName, prompt: Text("Your name"))
                HeaderCaption(
                    explanation: "Shown as the creator of the generated files. Files added later in Xcode use the name of whoever creates them.",
                    example: "Created by \(author) on \(Date.now.formatted(date: .numeric, time: .omitted))."
                )
            }
            field("Team ID", text: $model.teamID, prompt: "Optional", field: .teamID)
        }

        Section("Target") {
            Picker("Minimum iOS", selection: $model.deploymentTarget) {
                ForEach(deploymentTargets, id: \.self) { Text("iOS \($0)").tag($0) }
            }
            .issueHighlight(model.isHighlighted(.deploymentTarget))
            .id(FormAnchor.field(.deploymentTarget))
            Picker("Devices", selection: $model.deviceFamily) {
                ForEach(DeviceFamily.allCases) { Text($0.displayName).tag($0) }
            }
            LabeledContent("Location") {
                HStack {
                    Text(model.outputDirectory.path(percentEncoded: false))
                        .lineLimit(1)
                        .truncationMode(.head)
                        .foregroundStyle(.secondary)
                        .help(model.outputDirectory.path(percentEncoded: false))
                    Button("Choose…") { model.chooseOutputDirectory() }
                }
            }
            IssueText(issues: model.issues(for: .outputDirectory))
        }
        .issueHighlight(model.isHighlighted(.outputDirectory))
        .id(FormAnchor.field(.outputDirectory))
    }

    /// Matches the generator, which drops a trailing period so the header doesn't read "Inc.. All rights reserved."
    private var copyrightHolder: String {
        let name = model.organizationName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return "Company Inc" }
        return name.hasSuffix(".") ? String(name.dropLast()) : name
    }

    private var author: String {
        let name = model.authorName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Your name" : name
    }

    @ViewBuilder
    private func field(
        _ title: String,
        text: Binding<String>,
        prompt: String,
        field: ValidationIssue.Field,
        hideWhenEmpty: Bool = false,
        @ViewBuilder description: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: text, prompt: Text(prompt))
            description()
            // Empty required fields only complain once the user asked to see what needs fixing.
            if !(hideWhenEmpty && text.wrappedValue.isEmpty) || model.highlightsIssues {
                IssueText(issues: model.issues(for: field))
            }
        }
        .issueHighlight(model.isHighlighted(field))
        .id(FormAnchor.field(field))
    }
}

/// Explains where a value ends up, with a preview of the file header line it produces.
private struct HeaderCaption: View {
    let explanation: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("//  \(example)")
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.tail)
                .textSelection(.enabled)
        }
    }
}
