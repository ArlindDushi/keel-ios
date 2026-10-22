import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    let store: StoreOf<HomeFeature>

    var body: some View {
        content
            .navigationTitle("Home")
            .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var content: some View {
        if let message = store.errorMessage {
            ContentUnavailableView {
                Label("Something went wrong", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    store.send(.retryTapped)
                }
            }
        } else if store.isLoading && store.items.isEmpty {
            ProgressView()
        } else {
            List(store.items) { item in
                Button {
                    store.send(.itemTapped(item))
                } label: {
                    ItemRow(title: item.title, subtitle: item.subtitle)
                }
                .foregroundStyle(.primary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        })
    }
}
