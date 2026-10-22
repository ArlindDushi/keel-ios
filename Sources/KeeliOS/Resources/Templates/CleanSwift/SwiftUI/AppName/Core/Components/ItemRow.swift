import SwiftUI

struct ItemRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.extraSmall)
    }
}
