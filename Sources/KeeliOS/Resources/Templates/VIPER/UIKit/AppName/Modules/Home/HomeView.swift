import UIKit

/// The Home screen's view hierarchy. It has no logic; its controller fills it.
final class HomeView: UIView {
    static let cellIdentifier = "ItemCell"

    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func setUpLayout() {
        backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        activityIndicator.hidesWhenStopped = true

        addSubview(tableView)
        addSubview(activityIndicator)
        tableView.pinEdges(to: self)
        activityIndicator.center(in: self)
    }
}
