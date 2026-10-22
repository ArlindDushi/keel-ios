import SwiftUI

struct ItemDetailView: View {
    let title: String
    let subtitle: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(title)
                    .font(.largeTitle.bold())
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.medium)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
