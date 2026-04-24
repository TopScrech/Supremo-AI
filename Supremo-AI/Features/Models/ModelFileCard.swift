import ScrechKit

struct ModelFileCard: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let model: ModelFile
    
    private var sizeDescription: String {
        guard model.isPartialDownload == true else {
            return model.sizeDescription
        }
        
        return appModel.downloadStates[completeFileName]?.statusText ?? model.sizeDescription
    }
    
    private var completeFileName: String {
        let downloadFileSuffix = ".download"
        return model.fileName.hasSuffix(downloadFileSuffix) ? String(model.fileName.dropLast(downloadFileSuffix.count)) : model.fileName
    }
    
    private var downloadState: DownloadState? {
        appModel.downloadStates[completeFileName]
    }
    
    init(_ model: ModelFile) {
        self.model = model
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(model.displayName)
                .headline()
            
            HStack {
                Label(model.quantization, systemImage: "tag")
                Label(sizeDescription, systemImage: "internaldrive")
                
                if model.isMultimodalProjector {
                    Label("Projector", systemImage: "photo")
                }
                
                if model.isPartialDownload == true, downloadState?.isDownloading != true {
                    Label("Partial download", systemImage: "hourglass")
                }
            }
            .labelIconToTitleSpacing(2)
            .caption()
            .foregroundStyle(.tertiary)
            
            HStack {
                if model.isAvailableLocally {
                    if let chat = appModel.selectedChat {
                        Button("Use for Current Chat") {
                            appModel.assignModel(model, to: chat)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.foreground)
                    }
                } else if model.isPartialDownload == true, downloadState?.isDownloading != true {
                    Button("Continue Download", action: continueDownload)
                        .buttonStyle(.glassProminent)
                        .padding(.top, 5)
                }
            }
            
            if model.isPartialDownload == true, downloadState?.isDownloading == true {
                ProgressView(value: downloadState?.progress)
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
    
    private func continueDownload() {
        Task {
            await appModel.continueDownload(model)
        }
    }
}
