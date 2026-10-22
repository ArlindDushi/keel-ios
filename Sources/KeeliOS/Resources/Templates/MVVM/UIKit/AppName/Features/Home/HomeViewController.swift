import UIKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let homeView = HomeView()

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
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
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        Task { await viewModel.load() }
    }

    private func render(_ state: HomeViewModel.State) {
        homeView.setLoading(state == .loading)
        homeView.tableView.reloadData()
        if case let .failed(message) = state {
            showError(message)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: String(localized: "Something went wrong"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "Try Again"), style: .default) { [weak self] _ in
            guard let self else { return }
            Task { await self.viewModel.load() }
        })
        present(alert, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeView.cellIdentifier, for: indexPath)
        let item = viewModel.items[indexPath.row]
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
        viewModel.selectItem(at: indexPath.row)
    }
}
