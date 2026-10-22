import Foundation

@MainActor
protocol HomeBusinessLogic: AnyObject {
    func fetchItems(request: Home.FetchItems.Request) async
    func selectItem(request: Home.SelectItem.Request)
}

/// Data the router passes on to the next scene.
@MainActor
protocol HomeDataStore: AnyObject {
    var selectedItem: Item? { get }
}

@MainActor
final class HomeInteractor: HomeBusinessLogic, HomeDataStore {
    var presenter: (any HomePresentationLogic)?
    private let worker: HomeWorker
    private var items: [Item] = []
    private(set) var selectedItem: Item?

    init(worker: HomeWorker) {
        self.worker = worker
    }

    func fetchItems(request: Home.FetchItems.Request) async {
        do {
            items = try await worker.fetchItems()
            presenter?.presentItems(response: Home.FetchItems.Response(result: .success(items)))
        } catch {
            presenter?.presentItems(response: Home.FetchItems.Response(result: .failure(error)))
        }
    }

    func selectItem(request: Home.SelectItem.Request) {
        guard items.indices.contains(request.index) else { return }
        let item = items[request.index]
        selectedItem = item
        presenter?.presentSelectedItem(response: Home.SelectItem.Response(item: item))
    }
}
