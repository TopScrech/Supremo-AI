import ScrechKit

struct ModelFileCard: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let model: ModelFile
    
    init(_ model: ModelFile) {
        self.model = model
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.displayName)
                .headline()
            
            HStack {
                Label(model.quantization, systemImage: "tag")
                Label(model.sizeDescription, systemImage: "internaldrive")
                
                if model.isMultimodalProjector {
                    Label("Projector", systemImage: "photo")
                }
                
                if model.isPartialDownload == true {
                    Label("Partial download", systemImage: "hourglass")
                }
            }
            .labelIconToTitleSpacing(2)
            .caption()
            .foregroundStyle(.tertiary)
            
            if let chat = appModel.selectedChat {
                HStack {
                    if model.isAvailableLocally {
                        Button("Use for Current Chat") {
                            appModel.assignModel(model, to: chat)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.foreground)
                    }
                }
            }
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                appModel.deleteModel(model)
            }
        }
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                appModel.deleteModel(model)
            }
        }
    }
}
