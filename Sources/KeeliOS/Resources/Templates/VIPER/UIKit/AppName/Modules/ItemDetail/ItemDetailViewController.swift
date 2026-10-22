import UIKit

final class ItemDetailViewController: UIViewController {
    private let item: Item
    private let contentView = ItemDetailContentView()

    init(item: Item) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        contentView.titleLabel.text = item.title
        contentView.subtitleLabel.text = item.subtitle
    }
}
