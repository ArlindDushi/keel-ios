import ComposableArchitecture

/// Root feature: owns the Home screen and the navigation stack pushed on top of it.
@Reducer
struct AppFeature {
    @Reducer
    enum Path {
        case itemDetail(ItemDetailFeature)
    }

    @ObservableState
    struct State: Equatable {
        var home = HomeFeature.State()
        var path = StackState<Path.State>()
    }

    enum Action {
        case home(HomeFeature.Action)
        case path(StackActionOf<Path>)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }
        Reduce { state, action in
            switch action {
            case let .home(.itemTapped(item)):
                state.path.append(.itemDetail(ItemDetailFeature.State(item: item)))
                return .none
            case .home, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

extension AppFeature.Path.State: Equatable {}
