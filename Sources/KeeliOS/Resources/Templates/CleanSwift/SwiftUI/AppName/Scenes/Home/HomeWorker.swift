import Foundation

/// Does the work the interactor delegates: talking to services and APIs.
struct HomeWorker: Sendable {
    private let itemService: any ItemServicing

    init(itemService: any ItemServicing) {
        self.itemService = itemService
    }

    func fetchItems() async throws -> [Item] {
        try await itemService.fetchItems()
    }
}
