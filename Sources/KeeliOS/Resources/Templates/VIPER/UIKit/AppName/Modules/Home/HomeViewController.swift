import UIKit

final class HomeViewController: UIViewController {
    private let presenter: any HomePresenterProtocol
    private let homeView = HomeView()
    private var items: [HomeItemViewModel] = []

    init(presenter: any HomePresenterProtocol) {
        self.presenter = presenter
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
        presenter.viewDidLoad()
    }
}

extension HomeViewController: HomeViewProtocol {
    func display(_ items: [HomeItemViewModel]) {
        self.items = items
        homeView.tableView.reloadData()
    }

    func displayLoading(_ isLoading: Bool) {
        homeView.setLoading(isLoading)
    }

    func displayError(_ message: String) {
        let alert = UIAlertController(title: String(localized: "Something went wrong"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "Try Again"), style: .default) { [weak self] _ in
            self?.presenter.didTapRetry()
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
        presenter.didSelectItem(at: indexPath.row)
    }
}
