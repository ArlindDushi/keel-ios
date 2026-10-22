import KeeliOS
import SwiftUI

/// Right-hand column: the folder tree that will be generated and the Create button.
struct PreviewPane: View {
    @Environment(ProjectFormModel.self) private var model

    var body: some View {
        let issues = model.issues
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.appName.isEmpty ? "Project Preview" : model.appName)
                    .font(.headline)
                Text("\(model.pattern.displayName) · \(model.uiFramework.displayName) · \(model.environments.count) environments")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(FileNode.tree(from: model.plannedFiles)) { node in
                        FileNodeRow(node: node, depth: 0)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                if !issues.isEmpty {
                    Button {
                        model.showNextIssue()
                    } label: {
                        Label(issues.count == 1 ? "1 thing to fix" : "\(issues.count) things to fix", systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(Color.issue)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Show what needs fixing:\n" + issues.map(\.message).joined(separator: "\n"))
                    .accessibilityHint("Highlights the fields that need fixing and scrolls to the next one")
                }
                Button {
                    model.generate()
                } label: {
                    Text("Create Project")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!issues.isEmpty || model.isGenerating)
            }
            .padding()
        }
        .background(.background.secondary)
        .onChange(of: issues.isEmpty) { _, isEmpty in
            if isEmpty { model.highlightsIssues = false }
        }
    }
}

struct FileNode: Identifiable {
    let name: String
    let path: String
    var children: [FileNode]

    var id: String { path }
    var isDirectory: Bool { !children.isEmpty || name.hasSuffix(".xcodeproj") }

    /// Builds a tree from relative paths; folders first, then files, alphabetically.
    static func tree(from paths: [String]) -> [FileNode] {
        final class Builder {
            var children: [String: Builder] = [:]
        }
        let root = Builder()
        for path in paths {
            var node = root
            for component in path.split(separator: "/").map(String.init) {
                if node.children[component] == nil { node.children[component] = Builder() }
                node = node.children[component]!
            }
        }
        func makeNodes(_ builder: Builder, parent: String) -> [FileNode] {
            builder.children.map { name, child in
                let path = parent.isEmpty ? name : "\(parent)/\(name)"
                return FileNode(name: name, path: path, children: makeNodes(child, parent: path))
            }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
        return makeNodes(root, parent: "")
    }
}

private struct FileNodeRow: View {
    let node: FileNode
    let depth: Int
    @State private var isExpanded: Bool

    init(node: FileNode, depth: Int) {
        self.node = node
        self.depth = depth
        _isExpanded = State(initialValue: depth < 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.secondary)
                    .opacity(node.children.isEmpty ? 0 : 1)
                    .frame(width: 10)
                Image(systemName: icon)
                    .foregroundStyle(node.isDirectory ? Color.accentColor : .secondary)
                    .frame(width: 16)
                Text(node.name)
                    .lineLimit(1)
            }
            .font(.callout)
            .padding(.leading, CGFloat(depth) * 14 + 12)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !node.children.isEmpty else { return }
                withAnimation(.snappy(duration: 0.15)) { isExpanded.toggle() }
            }

            if isExpanded {
                ForEach(node.children) { child in
                    FileNodeRow(node: child, depth: depth + 1)
                }
            }
        }
    }

    private var icon: String {
        if node.name.hasSuffix(".xcodeproj") { return "hammer.fill" }
        if node.isDirectory { return "folder.fill" }
        switch (node.name as NSString).pathExtension {
        case "swift": return "swift"
        case "xcconfig", "yml", "plist", "xcprivacy": return "gearshape"
        case "json", "xcstrings": return "curlybraces"
        case "md": return "doc.richtext"
        case "sh": return "terminal"
        default: return "doc"
        }
    }
}
