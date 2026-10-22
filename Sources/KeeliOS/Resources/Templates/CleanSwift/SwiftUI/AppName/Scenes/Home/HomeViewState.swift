import Foundation
import Observation

@MainActor
protocol HomeDisplayLogic: AnyObject {
    func displayItems(viewModel: Home.FetchItems.ViewModel)
    func displayError(viewModel: Home.FetchItems.ErrorViewModel)
    func displaySelectedItem(viewModel: Home.SelectItem.ViewModel)
}

/// The display side of the VIP cycle in SwiftUI: the presenter writes to it and `HomeView` renders it.
@MainActor
@Observable
final class HomeViewState: HomeDisplayLogic {
    private(set) var displayedItems: [Home.FetchItems.ViewModel.DisplayedItem] = []
    var isLoading = false
    private(set) var errorMessage: String?
    var isShowingItemDetail = false

    func displayItems(viewModel: Home.FetchItems.ViewModel) {
        isLoading = false
        errorMessage = nil
        displayedItems = viewModel.displayedItems
    }

    func displayError(viewModel: Home.FetchItems.ErrorViewModel) {
        isLoading = false
        errorMessage = viewModel.message
    }

    func displaySelectedItem(viewModel: Home.SelectItem.ViewModel) {
        isShowingItemDetail = true
    }
}
