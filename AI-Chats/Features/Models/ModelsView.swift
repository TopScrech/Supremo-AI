import SwiftUI
import UniformTypeIdentifiers

struct ModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    @State private var showImporter = false

    var body: some View {
        List {
            Section("Install") {
                Button("Import GGUF Model", systemImage: "square.and.arrow.down") {
                    showImporter = true
                }
                Text("Imported models are copied into the app documents folder and can be selected in each chat")
                    .foregroundStyle(.secondary)
            }

            Section("Local Models") {
                if appModel.modelFiles.isEmpty {
                    ContentUnavailableView("No Local Models", systemImage: "shippingbox", description: Text("Import a GGUF model or download one from the catalog"))
                } else {
                    ForEach(appModel.modelFiles) { model in
                        ModelFileRowView(model: model)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    appModel.deleteModel(model)
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Models")
        .toolbar {
            Button("Import GGUF", systemImage: "square.and.arrow.down") {
                showImporter = true
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            if let url = try? result.get() {
                appModel.importModel(from: url)
            }
        }
    }
}
