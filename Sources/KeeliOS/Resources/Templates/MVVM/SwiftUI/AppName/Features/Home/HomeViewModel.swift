import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Item])
        case failed(String)
    }

    private(set) var state: State = .idle
    private let itemService: any ItemServicing
    private let router: Router

    init(itemService: any ItemServicing, router: Router) {
        self.itemService = itemService
        self.router = router
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await itemService.fetchItems())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func select(_ item: Item) {
        router.push(.itemDetail(item))
    }
}
