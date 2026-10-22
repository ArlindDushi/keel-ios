import SwiftUI

/// Business logic: fetching and changing data.
protocol HomeInteractorProtocol: Sendable {
    func fetchItems() async throws -> [Item]
}

/// Builds the screens the module navigates to.
@MainActor
protocol HomeRouterProtocol {
    associatedtype Detail: View
    func detail(of item: Item) -> Detail
}

/// Display-ready data for one row.
struct HomeItemViewModel: Identifiable, Hashable {
    let id: Item.ID
    let title: String
    let subtitle: String
}
