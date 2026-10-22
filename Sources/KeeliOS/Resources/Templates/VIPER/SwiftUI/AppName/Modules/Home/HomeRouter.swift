import SwiftUI

struct HomeRouter: HomeRouterProtocol {
    func detail(of item: Item) -> some View {
        ItemDetailModuleBuilder.build(item: item)
    }
}
