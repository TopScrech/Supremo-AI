import ScrechKit

struct ModelFileCard: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    private let model: ModelFile
    
    private var displaySize: String {
        if model.isPartialDownload == true, let statusText = appModel.downloadStates[completeFileName]?.statusText {
            return statusText
        }
        
        guard
            let localURL = model.localURL,
            let fileSize = try? localURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
        else {
            return "Unknown size"
        }
        
        return fileSize.formatted(.byteCount(style: .file))
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
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(model.displayName)
                    .headline()
                
                HStack {
                    if model.isPartialDownload != true {
                        Label(model.quantization, systemImage: "tag")
                    }
                    
                    Label(displaySize, systemImage: "internaldrive")
                        .monospacedDigit()
                    
                    if model.isMultimodalProjector {
                        Label("Projector", systemImage: "photo")
                    }
                }
                .labelIconToTitleSpacing(2)
                .caption()
                .foregroundStyle(.tertiary)
                
                if model.isPartialDownload == true, downloadState?.isDownloading == true {
                    ProgressView(value: downloadState?.progress)
                }
            }
            
            Spacer()
            
            if model.isAvailableLocally {
                if let chat = appModel.selectedChat {
                    Button("Select") {
                        appModel.assignModel(model, to: chat)
                        dismiss()
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
