import UIKit

final class ItemDetailViewController: UIViewController {
    private let viewModel: ItemDetailViewModel
    private let contentView = ItemDetailContentView()

    init(viewModel: ItemDetailViewModel) {
        self.viewModel = viewModel
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
        contentView.titleLabel.text = viewModel.title
        contentView.subtitleLabel.text = viewModel.subtitle
    }
}
