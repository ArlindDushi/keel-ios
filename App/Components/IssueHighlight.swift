import SwiftUI

/// Outlines a form row in the issue color, without changing its layout.
private struct IssueHighlight: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.issue.opacity(0.1))
                        .strokeBorder(Color.issue, lineWidth: 1.5)
                        .padding(-6)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

extension View {
    func issueHighlight(_ isActive: Bool) -> some View {
        modifier(IssueHighlight(isActive: isActive))
    }
}
