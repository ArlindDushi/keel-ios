import Foundation

@MainActor
final class HomeViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Item])
        case failed(String)
    }

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    /// Called on every state change; the view controller re-renders.
    var onStateChange: ((State) -> Void)?
    /// Called when the user picks an item; the coordinator navigates.
    var onSelectItem: ((Item) -> Void)?

    private let itemService: any ItemServicing

    init(itemService: any ItemServicing) {
        self.itemService = itemService
    }

    var items: [Item] {
        guard case let .loaded(items) = state else { return [] }
        return items
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await itemService.fetchItems())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func selectItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        onSelectItem?(items[index])
    }
}
