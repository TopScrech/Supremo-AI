import ScrechKit
import UniformTypeIdentifiers

struct ModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @State private var showImporter = false
    @AppStorage("modelsSortOrder") private var sortOrder = ModelSortOrder.family
    
    private var sortedModels: [ModelFile] {
        switch sortOrder {
        case .family:
            appModel.modelFiles.sorted {
                let firstFamily = $0.family.label
                let secondFamily = $1.family.label
                
                if firstFamily == secondFamily {
                    return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
                
                return firstFamily.localizedStandardCompare(secondFamily) == .orderedAscending
            }
            
        case .size:
            appModel.modelFiles.sorted {
                let firstSize = modelSize($0)
                let secondSize = modelSize($1)
                
                if firstSize == secondSize {
                    return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
                
                return firstSize < secondSize
            }
        }
    }
    
    var body: some View {
        List {
            Button {
                showImporter = true
            } label: {
                HStack {
                    Text("Import from Files")
                    
                    Spacer()
                    
                    Image(systemName: "square.and.arrow.down")
                        .secondary()
                }
            }
            .foregroundStyle(.foreground)
            
            Picker("Sort by", selection: $sortOrder) {
                ForEach(ModelSortOrder.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            .disabled(appModel.modelFiles.isEmpty)
            
            Section {
                if appModel.modelFiles.isEmpty {
                    ContentUnavailableView("No Local Models", systemImage: "shippingbox", description: Text("Import a GGUF model or download one from the catalog"))
                } else {
                    ForEach(sortedModels) {
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
        .scrollIndicators(.never)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            if let url = try? result.get() {
                appModel.importModel(from: url)
            }
        }
    }
    
    private func modelSize(_ model: ModelFile) -> Int {
        guard
            let localURL = model.localURL,
            let fileSize = try? localURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        else {
            return 0
        }
        
        return fileSize
    }
}
