import Foundation

/// Request, Response and ViewModel types for each Home use case.
/// Request: view → interactor. Response: interactor → presenter. ViewModel: presenter → view.
enum Home {
    enum FetchItems {
        struct Request {}

        struct Response {
            let result: Result<[Item], any Error>
        }

        struct ViewModel {
            struct DisplayedItem: Hashable {
                let title: String
                let subtitle: String
            }

            let displayedItems: [DisplayedItem]
        }

        struct ErrorViewModel {
            let message: String
        }
    }

    enum SelectItem {
        struct Request {
            let index: Int
        }

        struct Response {
            let item: Item
        }

        struct ViewModel {}
    }
}
