import SwiftUI

struct ItemDetailView: View {
    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(viewModel.title)
                    .font(.largeTitle.bold())
                Text(viewModel.subtitle)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.medium)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ItemDetailView(viewModel: ItemDetailViewModel(item: Item.samples[0]))
    }
}
