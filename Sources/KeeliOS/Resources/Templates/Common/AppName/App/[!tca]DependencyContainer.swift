import Foundation

/// Composition root: creates the app's shared services once and hands them to features.
/// Add new services here instead of creating them inside screens.
@MainActor
final class DependencyContainer {
    let apiClient: any APIClientProtocol
    let itemService: any ItemServicing

    init(apiClient: any APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
        self.itemService = ItemService(apiClient: apiClient)
    }
}
