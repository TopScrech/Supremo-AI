import ScrechKit
import UniformTypeIdentifiers

struct ModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    @AppStorage("modelsSortOrder") private var sortOrder = ModelSortOrder.family
    
    @State private var showImporter = false
    @State private var isDeleteAllPresented = false
    
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
            
            if !appModel.modelFiles.isEmpty {
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(ModelSortOrder.allCases) {
                        Text($0.label)
                            .tag($0)
                    }
                }
            }
            
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
                    
                    if !appModel.modelFiles.isEmpty {
                        Text("Total: \(appModel.localModelsSizeDescription)")
                            .secondary()
                    }
                }
            }
            
            if !appModel.modelFiles.isEmpty {
                Button("Delete all", systemImage: "trash", role: .destructive) {
                    isDeleteAllPresented = true
                }
                .foregroundStyle(.red)
            }
        }
        .scrollIndicators(.never)
        .animation(.default, value: appModel.modelFiles)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            if let url = try? result.get() {
                appModel.importModel(from: url)
            }
        }
        .alert("Delete all local models?", isPresented: $isDeleteAllPresented) {
            Button("Delete all", systemImage: "trash", role: .destructive, action: appModel.deleteAllModels)
        } message: {
            Text("This removes every local model file and clears model selection from chats")
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
