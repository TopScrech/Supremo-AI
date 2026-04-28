import ScrechKit

struct DownloadableModelCard: View {
    @Environment(ChatAppModel.self) private var appModel
    @State private var isNotForAllAudiencesAlertPresented = false
    @State private var isCheckingNotForAllAudiences = false
    
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
        
        HStack {
            VStack(alignment: .leading, spacing: 5) {
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
                    prepareDownload()
                }
                .disabled(capacityErrorMessage != nil || isCheckingNotForAllAudiences)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
            }
        }
        .contextMenu {
            Button("Copy Download Link", systemImage: "link", action: copyDownloadLink)
        }
        .alert("Not for all audiences", isPresented: $isNotForAllAudiencesAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Download", action: startDownload)
        } message: {
            Text("This repository has been marked as containing sensitive content and may contain potentially harmful and sensitive information")
        }
    }

    private func prepareDownload() {
        guard !isCheckingNotForAllAudiences else { return }

        isCheckingNotForAllAudiences = true
        
        Task {
            if await appModel.isMarkedNotForAllAudiences(model) {
                isNotForAllAudiencesAlertPresented = true
            } else {
                startDownload()
            }
            
            isCheckingNotForAllAudiences = false
        }
    }

    private func startDownload() {
        Task {
            await appModel.download(model)
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
