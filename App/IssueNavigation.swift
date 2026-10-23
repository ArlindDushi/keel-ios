import KeeliOS
import SwiftUI

/// Asks the form to scroll to a row. A new value is created for every request,
/// so asking for the same row twice still scrolls.
struct ScrollRequest: Equatable {
    let anchor: String
    private let id = UUID()

    init(anchor: String) {
        self.anchor = anchor
    }
}

/// Scroll anchors of the form rows that can have issues.
enum FormAnchor {
    static func field(_ field: ValidationIssue.Field) -> String { "field-\(field)" }
    static func catalogEntry(_ id: String) -> String { "catalog-\(id)" }
}

extension ProjectFormModel {
    /// Whether the row for `field` is outlined as needing a fix.
    func isHighlighted(_ field: ValidationIssue.Field) -> Bool {
        highlightsIssues && !issues(for: field).isEmpty
    }

    /// A catalog package that's selected without any product.
    func isHighlighted(_ entry: SDKCatalogEntry) -> Bool {
        highlightsIssues && selectedProducts[entry.id]?.isEmpty == true
    }

    /// Turns on highlighting and scrolls to the next row that needs fixing; repeated calls cycle through them.
    func showNextIssue() {
        highlightsIssues = true
        var anchors: [String] = []
        for issue in issues {
            let anchor = anchor(for: issue.field)
            if !anchors.contains(anchor) { anchors.append(anchor) }
        }
        guard !anchors.isEmpty else { return }
        scrollRequest = ScrollRequest(anchor: anchors[issueCursor % anchors.count])
        issueCursor += 1
    }
}

private extension ProjectFormModel {
    func anchor(for field: ValidationIssue.Field) -> String {
        // Packages picked from the catalog are rebuilt on every change, so their issues point at the catalog row.
        if case let .package(id) = field, !customPackages.contains(where: { $0.id == id }),
           let entry = availableCatalog.first(where: { selectedProducts[$0.id]?.isEmpty == true }) {
            return FormAnchor.catalogEntry(entry.id)
        }
        return FormAnchor.field(field)
    }
}
