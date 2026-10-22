import UIKit

/// Controller of the Home screen: loads items from the service and shows them in `HomeView`.
final class HomeViewController: UIViewController {
    private let itemService: any ItemServicing
    private let homeView = HomeView()
    private var items: [Item] = [] {
        didSet { homeView.tableView.reloadData() }
    }

    init(itemService: any ItemServicing) {
        self.itemService = itemService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Home")
        homeView.tableView.dataSource = self
        homeView.tableView.delegate = self
        Task { await loadItems() }
    }

    private func loadItems() async {
        homeView.setLoading(true)
        defer { homeView.setLoading(false) }
        do {
            items = try await itemService.fetchItems()
        } catch {
            showError(error)
        }
    }

    private func showError(_ error: any Error) {
        let alert = UIAlertController(
            title: String(localized: "Something went wrong"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Try Again"), style: .default) { [weak self] _ in
            Task { await self?.loadItems() }
        })
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeView.cellIdentifier, for: indexPath)
        let item = items[indexPath.row]
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
        let detail = ItemDetailViewController(item: items[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }
}
