import Foundation

/// A folder of template files copied into the generated project.
///
/// Path components may carry a condition and placeholders:
/// - `[tests]AppNameTests` is only kept when the `tests` flag is set (`[!flag]` for the opposite,
///   any `TemplateContext` condition works).
/// - `AppName` is replaced with the app name.
/// - A leading `_.` becomes `.` (`_.gitignore` → `.gitignore`), so dotfiles survive resource copying.
public struct TemplateTree: Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public struct File: Hashable, Sendable {
        public let source: URL
        /// Path relative to the project directory, with conditions removed and placeholders applied.
        public let destination: String
    }

    public func files(context: TemplateContext, appName: String) throws -> [File] {
        let keys: [URLResourceKey] = [.isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: keys) else {
            return []
        }
        var files: [File] = []
        let rootComponents = root.standardizedFileURL.pathComponents
        for case let url as URL in enumerator {
            guard try url.resourceValues(forKeys: Set(keys)).isRegularFile == true, url.lastPathComponent != ".DS_Store" else {
                continue
            }
            let components = url.standardizedFileURL.pathComponents.dropFirst(rootComponents.count)
            var destination: [String] = []
            var included = true
            for component in components {
                guard let resolved = try Self.resolve(component, context: context, appName: appName) else {
                    included = false
                    break
                }
                destination.append(resolved)
            }
            if included {
                files.append(File(source: url, destination: destination.joined(separator: "/")))
            }
        }
        return files.sorted { $0.destination < $1.destination }
    }

    /// Returns `nil` when the component's condition isn't met.
    static func resolve(_ component: String, context: TemplateContext, appName: String) throws -> String? {
        var name = component
        if name.hasPrefix("["), let end = name.firstIndex(of: "]") {
            let condition = String(name[name.index(after: name.startIndex)..<end])
            guard try context.evaluate(condition) else { return nil }
            name = String(name[name.index(after: end)...])
        }
        if name.hasPrefix("_.") {
            name.removeFirst()
        }
        return name.replacingOccurrences(of: "AppName", with: appName)
    }
}
