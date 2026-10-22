import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            HomeView(store: store.scope(state: \.home, action: \.home))
        } destination: { store in
            switch store.case {
            case let .itemDetail(store):
                ItemDetailView(store: store)
            }
        }
    }
}
