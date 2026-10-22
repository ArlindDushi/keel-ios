import Foundation

struct HomeInteractor: HomeInteractorProtocol {
    private let itemService: any ItemServicing

    init(itemService: any ItemServicing) {
        self.itemService = itemService
    }

    func fetchItems() async throws -> [Item] {
        try await itemService.fetchItems()
    }
}
