import KeeliOS
import SwiftUI

struct ArchitectureSection: View {
    @Environment(ProjectFormModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Section("Architecture") {
            Picker("User interface", selection: $model.uiFramework) {
                ForEach(UIFramework.allCases) { Text($0.displayName).tag($0) }
            }
            .pickerStyle(.segmented)

            ForEach(ArchitecturePattern.allCases) { pattern in
                PatternRow(
                    pattern: pattern,
                    isSelected: model.pattern == pattern,
                    isAvailable: pattern.supports(model.uiFramework)
                ) {
                    model.pattern = pattern
                }
            }
        }
    }
}

private struct PatternRow: View {
    let pattern: ArchitecturePattern
    let isSelected: Bool
    let isAvailable: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(pattern.displayName).font(.headline)
                        if !isAvailable {
                            Text("\(pattern.supportedFrameworks.map(\.displayName).joined(separator: ", ")) only")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    Text(pattern.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .opacity(isAvailable ? 1 : 0.45)
        .help(isAvailable ? "" : "\(pattern.displayName) isn't available for this user interface framework.")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
