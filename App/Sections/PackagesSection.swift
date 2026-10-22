import KeeliOS
import SwiftUI

struct PackagesSection: View {
    @Environment(ProjectFormModel.self) private var model
    @State private var isAddingPackage = false

    var body: some View {
        Section {
            if model.pattern == .tca {
                LabeledContent {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                } label: {
                    Text("swift-composable-architecture")
                    Text("Required by The Composable Architecture")
                }
            }
            ForEach(model.availableCatalog) { entry in
                CatalogRow(entry: entry)
            }
        } header: {
            Text("Remote SDKs")
        } footer: {
            Text("Packages are added with Swift Package Manager, “up to next major” from the version shown.")
                .foregroundStyle(.secondary)
        }

        Section("Custom Packages") {
            ForEach(model.customPackages) { package in
                CustomPackageRow(package: package)
            }
            Button("Add Package…", systemImage: "plus") {
                isAddingPackage = true
            }
        }
        .sheet(isPresented: $isAddingPackage) {
            CustomPackageSheet()
        }
    }
}

private struct CatalogRow: View {
    @Environment(ProjectFormModel.self) private var model
    let entry: SDKCatalogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: Binding(get: { model.isSelected(entry) }, set: { model.setSelected($0, entry) })) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.name)
                    Text(entry.version)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                Text(entry.summary)
            }
            if model.isSelected(entry), entry.products.count > 1 {
                ProductPicker(entry: entry)
                    .padding(.leading, 22)
            }
        }
        .issueHighlight(model.isHighlighted(entry))
        .id(FormAnchor.catalogEntry(entry.id))
    }
}

private struct ProductPicker: View {
    @Environment(ProjectFormModel.self) private var model
    let entry: SDKCatalogEntry

    private let columns = [GridItem(.adaptive(minimum: 170), alignment: .leading)]

    var body: some View {
        let selected = model.selectedProducts[entry.id] ?? []
        VStack(alignment: .leading, spacing: 4) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                ForEach(entry.products, id: \.self) { product in
                    Toggle(product, isOn: Binding(
                        get: { selected.contains(product) },
                        set: { model.setProduct(product, selected: $0, of: entry) }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.callout)
                }
            }
            if selected.isEmpty {
                Label("Choose at least one product.", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.issue)
            }
        }
    }
}

private struct CustomPackageRow: View {
    @Environment(ProjectFormModel.self) private var model
    let package: RemotePackage

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                Text("\(package.url) · \(package.requirement.summary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(package.products.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                IssueText(issues: model.issues(for: .package(package.id)))
            }
            Spacer()
            Button("Remove", systemImage: "minus.circle.fill") {
                model.customPackages.removeAll { $0.id == package.id }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .issueHighlight(model.isHighlighted(.package(package.id)))
        .id(FormAnchor.field(.package(package.id)))
    }
}

extension RemotePackage.Requirement {
    var summary: String {
        switch self {
        case let .upToNextMajor(version): "from \(version)"
        case let .upToNextMinor(version): "up to next minor from \(version)"
        case let .exact(version): "exactly \(version)"
        case let .branch(branch): "branch \(branch)"
        }
    }
}
