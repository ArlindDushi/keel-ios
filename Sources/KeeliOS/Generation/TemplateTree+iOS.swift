import Foundation
import KeelCore

extension TemplateTree {
    /// The template folders used for a pattern + UI framework, in copy order.
    static func trees(for pattern: ArchitecturePattern, framework: UIFramework) throws -> [TemplateTree] {
        guard let templates = Bundle.module.url(forResource: "Templates", withExtension: nil) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return [
            TemplateTree(root: templates.appending(path: "Common")),
            TemplateTree(root: templates.appending(path: pattern.templateFolder).appending(path: framework.templateFolder))
        ]
    }
}
