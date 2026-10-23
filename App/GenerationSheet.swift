import AppKit
import KeeliOS
import SwiftUI

struct GenerationSheet: View {
    @Environment(ProjectFormModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch model.phase {
            case .idle:
                EmptyView()
            case let .running(current):
                Text("Creating \(model.appName)…").font(.title2.bold())
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(steps, id: \.self) { step in
                        StepRow(step: step, current: current)
                    }
                }
            case let .finished(projectFile, warnings):
                Label("\(projectFile.deletingPathExtension().lastPathComponent) is ready", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                Text(projectFile.deletingLastPathComponent().path(percentEncoded: false))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                ForEach(warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                HStack {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([projectFile])
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                    Button("Open in Xcode") {
                        NSWorkspace.shared.open(projectFile)
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            case let .failed(message):
                Label("Couldn't create the project", systemImage: "xmark.octagon.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.red)
                ScrollView {
                    Text(message)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                HStack {
                    Spacer()
                    Button("Close") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(24)
        .frame(width: 460)
        .interactiveDismissDisabled(model.isGenerating)
    }
}

private extension GenerationSheet {
    var steps: [GenerationStep] {
        GenerationStep.allCases.filter { $0 != .initializingGit || model.extras.gitInit }
    }
}

private struct StepRow: View {
    let step: GenerationStep
    let current: GenerationStep

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if step.rawValue < current.rawValue {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else if step == current {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "circle").foregroundStyle(.tertiary)
                }
            }
            .frame(width: 18)
            Text(step.title)
                .foregroundStyle(step.rawValue > current.rawValue ? .secondary : .primary)
        }
    }
}
