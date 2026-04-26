import ScrechKit

struct DownloadableModelCard: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let model: DownloadableModel
    
    init(_ model: DownloadableModel) {
        self.model = model
    }
    
    var body: some View {
        let downloadState = appModel.downloadStates[model.fileName]
        
        let isDownloaded = appModel.modelFiles.contains {
            $0.fileName == model.fileName && $0.isAvailableLocally
        }
        
        let capacityErrorMessage = appModel.downloadCapacityErrorMessage(for: model)
        
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.familyName)
                        .headline()
                    
                    HStack {
                        Label(model.quantization, systemImage: "tag")
                        Label(model.displaySize, systemImage: "externaldrive")
                    }
                    .labelIconToTitleSpacing(2)
                    .caption()
                    .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                if isDownloaded {
                    SFButton("checkmark") {}
                        .foregroundStyle(.green)
                        .headline()
                        .disabled(true)
                        .buttonStyle(.glassProminent)
                        .buttonBorderShape(.circle)
                    
                } else if downloadState?.isDownloading != true {
                    SFButton("arrow.down") {
                        Task {
                            await appModel.download(model)
                        }
                    }
                    .disabled(capacityErrorMessage != nil)
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                }
            }
            
            if let downloadState, downloadState.isDownloading {
                ProgressView(value: downloadState.progress)
                
                Text(downloadState.statusText)
                    .caption()
                    .secondary()
                    .monospacedDigit()
                
            } else if let downloadState, let errorMessage = downloadState.errorMessage {
                Text(errorMessage)
                    .caption()
                    .foregroundStyle(.red)
                
            } else if let capacityErrorMessage {
                Text(capacityErrorMessage)
                    .caption()
                    .foregroundStyle(.red)
            }
        }
        .contextMenu {
            Button("Copy Download Link", systemImage: "link", action: copyDownloadLink)
        }
    }
    
    private func copyDownloadLink() {
#if os(iOS) || os(visionOS)
        UIPasteboard.general.string = model.url.absoluteString
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.url.absoluteString, forType: .string)
#endif
    }
}
