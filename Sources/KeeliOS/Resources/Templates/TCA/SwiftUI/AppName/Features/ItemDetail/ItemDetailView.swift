import ComposableArchitecture
import SwiftUI

struct ItemDetailView: View {
    let store: StoreOf<ItemDetailFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(store.item.title)
                    .font(.largeTitle.bold())
                Text(store.item.subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.medium)
        }
        .navigationTitle(store.item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                store.send(.favoriteTapped)
            } label: {
                Label("Favorite", systemImage: store.isFavorite ? "star.fill" : "star")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(store: Store(initialState: ItemDetailFeature.State(item: Item.samples[0])) {
            ItemDetailFeature()
        })
    }
}
