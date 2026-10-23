import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var items: [Item] = []
        var isLoading = false
        var errorMessage: String?
    }

    enum Action {
        case onAppear
        case retryTapped
        case itemsResponse(Result<[Item], any Error>)
        /// Handled by `AppFeature`, which pushes the detail screen.
        case itemTapped(Item)
    }

    @Dependency(\.itemClient) var itemClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.items.isEmpty, !state.isLoading else { return .none }
                return loadItems(&state)

            case .retryTapped:
                return loadItems(&state)

            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.items = items
                return .none

            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .itemTapped:
                return .none
            }
        }
    }
}

private extension HomeFeature {
    func loadItems(_ state: inout State) -> Effect<Action> {
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
            do {
                await send(.itemsResponse(.success(try await itemClient.fetchItems())))
            } catch {
                await send(.itemsResponse(.failure(error)))
            }
        }
    }
}
