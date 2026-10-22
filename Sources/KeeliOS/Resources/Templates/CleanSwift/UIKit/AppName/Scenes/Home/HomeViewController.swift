import UIKit

@MainActor
protocol HomeDisplayLogic: AnyObject {
    func displayItems(viewModel: Home.FetchItems.ViewModel)
    func displayError(viewModel: Home.FetchItems.ErrorViewModel)
    func displaySelectedItem(viewModel: Home.SelectItem.ViewModel)
}

final class HomeViewController: UIViewController {
    var interactor: (any HomeBusinessLogic)?
    var router: (any HomeRoutingLogic & HomeDataPassing)?

    private let homeView = HomeView()
    private var displayedItems: [Home.FetchItems.ViewModel.DisplayedItem] = []

    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Home")
        homeView.tableView.dataSource = self
        homeView.tableView.delegate = self
        fetchItems()
    }

    private func fetchItems() {
        homeView.setLoading(true)
        Task { await interactor?.fetchItems(request: Home.FetchItems.Request()) }
    }
}

extension HomeViewController: HomeDisplayLogic {
    func displayItems(viewModel: Home.FetchItems.ViewModel) {
        homeView.setLoading(false)
        displayedItems = viewModel.displayedItems
        homeView.tableView.reloadData()
    }

    func displayError(viewModel: Home.FetchItems.ErrorViewModel) {
        homeView.setLoading(false)
        let alert = UIAlertController(title: String(localized: "Something went wrong"), message: viewModel.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "Try Again"), style: .default) { [weak self] _ in
            self?.fetchItems()
        })
        present(alert, animated: true)
    }

    func displaySelectedItem(viewModel: Home.SelectItem.ViewModel) {
        router?.routeToItemDetail()
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeView.cellIdentifier, for: indexPath)
        let item = displayedItems[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        interactor?.selectItem(request: Home.SelectItem.Request(index: indexPath.row))
    }
}
