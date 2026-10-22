import KeeliOS
import SwiftUI

extension Color {
    /// Used for everything that needs fixing: messages, highlights and the "things to fix" button.
    static let issue = Color.orange
}

/// Validation messages shown under a field.
struct IssueText: View {
    let issues: [ValidationIssue]

    var body: some View {
        if !issues.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(issues) { issue in
                    Label(issue.message, systemImage: "exclamationmark.circle.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.issue)
        }
    }
}
