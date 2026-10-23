import KeeliOS
import SwiftUI

struct ContentView: View {
    @Environment(ProjectFormModel.self) private var model

    var body: some View {
        @Bindable var model = model
        HStack(spacing: 0) {
            ScrollViewReader { proxy in
                Form {
                    GeneralSection()
                    EnvironmentsSection()
                    ArchitectureSection()
                    PackagesSection()
                    ExtrasSection()
                }
                .formStyle(.grouped)
                .onChange(of: model.scrollRequest) { _, request in
                    guard let request else { return }
                    withAnimation { proxy.scrollTo(request.anchor, anchor: .center) }
                }
            }
            .frame(minWidth: 560)

            Divider()

            PreviewPane()
                .frame(width: 340)
        }
        .sheet(isPresented: isShowingGeneration) {
            GenerationSheet()
        }
        .confirmationDialog(
            "“\(model.pendingOverwrite?.lastPathComponent ?? "")” already exists",
            isPresented: isConfirmingOverwrite,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                model.generate(overwrite: true)
            }
            Button("Cancel", role: .cancel) {
                model.pendingOverwrite = nil
            }
        } message: {
            Text("Replacing it deletes everything in \(model.pendingOverwrite?.path ?? "").")
        }
    }
}

private extension ContentView {
    var isShowingGeneration: Binding<Bool> {
        Binding(
            get: { model.phase != .idle },
            set: { if !$0, !model.isGenerating { model.phase = .idle } }
        )
    }

    var isConfirmingOverwrite: Binding<Bool> {
        Binding(
            get: { model.pendingOverwrite != nil },
            set: { if !$0 { model.pendingOverwrite = nil } }
        )
    }
}
