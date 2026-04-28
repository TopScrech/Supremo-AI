import ScrechKit

struct DownloadableModelCard: View {
    @Environment(ChatAppModel.self) private var appModel
    @State private var isNotForAllAudiencesAlertPresented = false
    @State private var isCheckingNotForAllAudiences = false
    @State private var versionSelectionModel: DownloadableModel?
    
    private let model: DownloadableModel
    
    init(_ model: DownloadableModel) {
        self.model = model
    }
    
    var body: some View {
        let downloadState = appModel.downloadStateEntry(for: model.fileName).state
        
        let isDownloaded = appModel.modelFiles.contains {
            $0.fileName == model.fileName && $0.isAvailableLocally
        }
        
        let capacityErrorMessage = appModel.downloadCapacityErrorMessage(for: model)
        
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(model.familyName)
                        .headline()
                    
                    if model.supportsVersionSelection {
                        Label("Choose version", systemImage: "square.stack.3d.up")
                            .labelIconToTitleSpacing(2)
                            .caption()
                            .foregroundStyle(.tertiary)
                    } else {
                        HStack {
                            Label(model.quantization, systemImage: "tag")
                            Label(model.displaySize, systemImage: "externaldrive")
                        }
                        .labelIconToTitleSpacing(2)
                        .caption()
                        .foregroundStyle(.tertiary)
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
                    
                } else if let capacityErrorMessage, !model.supportsVersionSelection {
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
                    if model.supportsVersionSelection {
                        versionSelectionModel = model
                    } else {
                        prepareDownload()
                    }
                }
                .disabled((capacityErrorMessage != nil && !model.supportsVersionSelection) || isCheckingNotForAllAudiences)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
            }
        }
        .contentShape(.rect)
        .contextMenu {
            Button("Copy download link", systemImage: "link", action: copyDownloadLink)
            
            if model.huggingFaceModelCardURL != nil {
                Button("Copy model card link", systemImage: "link", action: copyHuggingFaceModelCardLink)
            }
        }
        .alert("Not for all audiences", isPresented: $isNotForAllAudiencesAlertPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Download", action: startDownload)
        } message: {
            Text("This repository has been marked as containing sensitive content and may contain potentially harmful and sensitive information")
        }
        .sheet(item: $versionSelectionModel) {
            DownloadableModelVersionsSheet($0)
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
        copy(model.url.absoluteString)
    }
    
    private func copyHuggingFaceModelCardLink() {
        guard let url = model.huggingFaceModelCardURL else { return }
        
        copy(url.absoluteString)
    }
    
    private func copy(_ text: String) {
#if os(iOS) || os(visionOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}
