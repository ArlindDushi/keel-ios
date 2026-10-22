import Foundation
import Observation

/// Turns interactor results into display state and handles the view's events.
@MainActor
@Observable
final class HomePresenter {
    private(set) var items: [HomeItemViewModel] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// The item whose detail is shown; drives navigation in `HomeView`.
    var selectedItem: Item?

    private let interactor: any HomeInteractorProtocol
    private var entities: [Item] = []

    init(interactor: any HomeInteractorProtocol) {
        self.interactor = interactor
    }

    func onAppear() async {
        guard entities.isEmpty, !isLoading else { return }
        await loadItems()
    }

    func loadItems() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            entities = try await interactor.fetchItems()
            items = entities.map { HomeItemViewModel(id: $0.id, title: $0.title, subtitle: $0.subtitle) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func didSelect(_ item: HomeItemViewModel) {
        selectedItem = entities.first { $0.id == item.id }
    }
}
