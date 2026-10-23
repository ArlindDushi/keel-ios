import KeeliOS
import SwiftUI

struct EnvironmentsSection: View {
    @Environment(ProjectFormModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section {
            ForEach($model.environments) { $environment in
                EnvironmentRow(environment: $environment)
            }
            IssueText(issues: model.issues(for: .environments))
                .issueHighlight(model.isHighlighted(.environments))
            Button("Add Environment", systemImage: "plus") {
                model.addEnvironment()
            }
            .id(FormAnchor.field(.environments))
        } header: {
            Text("Environments")
        } footer: {
            Text("Each environment gets its own scheme, a Debug and a Release configuration, and an xcconfig file.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct EnvironmentRow: View {
    @Environment(ProjectFormModel.self) private var model
    @Binding var environment: AppEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Name", text: name, prompt: Text("Staging"))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                    .labelsHidden()
                Spacer()
                Toggle("Production", isOn: isProduction)
                    .toggleStyle(.checkbox)
                    .help("The App Store build. Usually has no bundle ID or name suffix.")
                Button("Remove", systemImage: "minus.circle.fill") {
                    model.removeEnvironment(environment)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .disabled(model.environments.count == 1)
                .help("Remove environment")
            }
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    Text("Bundle ID suffix").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        TextField("Bundle ID suffix", text: $environment.bundleIDSuffix, prompt: Text("None"))
                            .labelsHidden()
                        ResultCaption(value: bundleID)
                    }
                }
                GridRow {
                    Text("Name suffix").foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        TextField("Name suffix", text: $environment.displayNameSuffix, prompt: Text("None"))
                            .labelsHidden()
                        ResultCaption(value: displayName)
                    }
                }
                GridRow {
                    Text("API base URL").foregroundStyle(.secondary)
                    TextField("API base URL", text: $environment.apiBaseURL, prompt: Text("https://api.example.com"))
                        .labelsHidden()
                }
            }
            .font(.callout)
            .textFieldStyle(.roundedBorder)
            IssueText(issues: model.issues(for: .environment(environment.id)))
        }
        .padding(.vertical, 4)
        .issueHighlight(model.isHighlighted(.environment(environment.id)))
        .id(FormAnchor.field(.environment(environment.id)))
    }
}

private extension EnvironmentRow {
    /// The bundle ID this environment builds with, e.g. "com.acme.weather.dev".
    var bundleID: String {
        let base = model.bundleID.trimmingCharacters(in: .whitespaces)
        return (base.isEmpty ? "com.company.app" : base) + environment.bundleIDSuffix
    }

    /// The home screen name of this environment's build, e.g. "Weather Dev".
    var displayName: String {
        let base = model.displayName.trimmingCharacters(in: .whitespaces)
        return (base.isEmpty ? "App" : base) + environment.displayNameSuffix
    }

    var name: Binding<String> {
        Binding(get: { environment.name }, set: { model.rename(environment, to: $0) })
    }

    var isProduction: Binding<Bool> {
        Binding(get: { environment.isProduction }, set: { if $0 { model.makeProduction(environment) } })
    }
}

/// Shows the value a field produces, under the field.
private struct ResultCaption: View {
    let value: String

    var body: some View {
        Label(value, systemImage: "arrow.turn.down.right")
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .help(value)
    }
}
