import Foundation

protocol ItemServicing: Sendable {
    func fetchItems() async throws -> [Item]
}

struct ItemService: ItemServicing {
    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchItems() async throws -> [Item] {
        // Replace the sample data with a request, for example:
        // try await apiClient.send(Endpoint(path: "items"), as: [Item].self)
        Item.samples
    }
}
