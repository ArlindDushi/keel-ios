import SwiftUI

/// Builds the scenes Home navigates to, using the data the interactor stored.
@MainActor
struct HomeRouter {
    let dataStore: any HomeDataStore

    @ViewBuilder
    func itemDetail() -> some View {
        if let item = dataStore.selectedItem {
            ItemDetailConfigurator.configure(item: item)
        }
    }
}
