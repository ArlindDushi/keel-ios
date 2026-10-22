import ComposableArchitecture
import Foundation

/// Fetches items. Features get it with `@Dependency(\.itemClient)`; tests override it.
@DependencyClient
struct ItemClient: Sendable {
    var fetchItems: @Sendable () async throws -> [Item]
}

extension ItemClient: DependencyKey {
    static let liveValue = ItemClient(
        fetchItems: {
            // Replace the sample data with a request, for example:
            // try await APIClient().send(Endpoint(path: "items"), as: [Item].self)
            Item.samples
        }
    )

    static let previewValue = ItemClient(fetchItems: { Item.samples })

    static let testValue = ItemClient()
}

extension DependencyValues {
    var itemClient: ItemClient {
        get { self[ItemClient.self] }
        set { self[ItemClient.self] = newValue }
    }
}
