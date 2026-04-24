import ScrechKit

struct DownloadableModelRowView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let model: DownloadableModel
    
    init(_ model: DownloadableModel) {
        self.model = model
    }
    
    var body: some View {
        let downloadState = appModel.downloadStates[model.fileName]
        
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
            
            if let downloadState, downloadState.isDownloading {
                ProgressView(value: downloadState.progress)
                
                Text(downloadState.statusText)
                    .caption()
                    .secondary()
                    .monospacedDigit()
            } else {
                HStack {
                    Button("Download", systemImage: "arrow.down.circle") {
                        Task {
                            await appModel.download(model)
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if let downloadState, let errorMessage = downloadState.errorMessage {
                        Text(errorMessage)
                            .caption()
                            .foregroundStyle(.red)
                    }
                }
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
