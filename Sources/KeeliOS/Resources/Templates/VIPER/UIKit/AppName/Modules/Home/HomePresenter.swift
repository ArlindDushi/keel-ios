import Foundation

@MainActor
final class HomePresenter: HomePresenterProtocol {
    weak var view: (any HomeViewProtocol)?
    private let interactor: any HomeInteractorProtocol
    private let router: any HomeRouterProtocol
    private var items: [Item] = []

    init(interactor: any HomeInteractorProtocol, router: any HomeRouterProtocol) {
        self.interactor = interactor
        self.router = router
    }

    func viewDidLoad() {
        Task { await loadItems() }
    }

    func didTapRetry() {
        Task { await loadItems() }
    }

    func didSelectItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        router.showDetail(of: items[index])
    }

    func loadItems() async {
        view?.displayLoading(true)
        defer { view?.displayLoading(false) }
        do {
            items = try await interactor.fetchItems()
            view?.display(items.map { HomeItemViewModel(title: $0.title, subtitle: $0.subtitle) })
        } catch {
            view?.displayError(error.localizedDescription)
        }
    }
}
