import ScrechKit
import UniformTypeIdentifiers

struct ModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @State private var showImporter = false
    
    var body: some View {
        List {
            Button("Import GGUF Model", systemImage: "square.and.arrow.down") {
                showImporter = true
            }
            .foregroundStyle(.foreground)
            
            Section {
                if appModel.modelFiles.isEmpty {
                    ContentUnavailableView("No Local Models", systemImage: "shippingbox", description: Text("Import a GGUF model or download one from the catalog"))
                } else {
                    ForEach(appModel.modelFiles) {
                        ModelFileCard($0)
                    }
                }
            } header: {
                HStack {
                    Text("Local Models")
                    
                    Spacer()
                    
                    Text("Total: \(appModel.localModelsSizeDescription)")
                        .secondary()
                }
            }
        }
        .navigationTitle("Models")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            if let url = try? result.get() {
                appModel.importModel(from: url)
            }
        }
    }
}
