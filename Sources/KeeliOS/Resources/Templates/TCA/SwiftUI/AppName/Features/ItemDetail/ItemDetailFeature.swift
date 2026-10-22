import ComposableArchitecture

@Reducer
struct ItemDetailFeature {
    @ObservableState
    struct State: Equatable {
        let item: Item
        var isFavorite = false
    }

    enum Action {
        case favoriteTapped
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .favoriteTapped:
                state.isFavorite.toggle()
                return .none
            }
        }
    }
}
