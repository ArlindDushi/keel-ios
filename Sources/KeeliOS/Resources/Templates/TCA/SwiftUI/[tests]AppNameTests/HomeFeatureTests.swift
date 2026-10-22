import ComposableArchitecture
import Testing
@testable import {{APP_NAME}}

@MainActor
struct HomeFeatureTests {
    @Test func onAppearLoadsItems() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.itemClient.fetchItems = { Item.samples }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.itemsResponse.success) {
            $0.isLoading = false
            $0.items = Item.samples
        }
    }

    @Test func failureShowsError() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.itemClient.fetchItems = { throw APIError.invalidResponse }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.itemsResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = APIError.invalidResponse.localizedDescription
        }
    }

    @Test func tappingAnItemPushesItsDetail() async {
        let item = Item.samples[0]
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.home(.itemTapped(item))) {
            $0.path[id: 0] = .itemDetail(ItemDetailFeature.State(item: item))
        }
    }
}
