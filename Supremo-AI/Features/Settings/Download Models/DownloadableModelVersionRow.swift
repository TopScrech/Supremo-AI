import ScrechKit

struct DownloadableModelVersionRow: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let model: DownloadableModel
    private let isCheckingNotForAllAudiences: Bool
    private let download: (DownloadableModel) -> Void
    
    init(_ model: DownloadableModel, isCheckingNotForAllAudiences: Bool, download: @escaping (DownloadableModel) -> Void) {
        self.model = model
        self.isCheckingNotForAllAudiences = isCheckingNotForAllAudiences
        self.download = download
    }
    
    var body: some View {
        let downloadState = appModel.downloadStateEntry(for: model.fileName).state
        
        let isDownloaded = appModel.modelFiles.contains {
            $0.fileName == model.fileName && $0.isAvailableLocally
        }
        
        let capacityErrorMessage = appModel.downloadCapacityErrorMessage(for: model)
        
        HStack {
            VStack(alignment: .leading) {
                Text(model.quantization)
                    .headline()
                
                HStack {
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
                Button("Download", systemImage: "arrow.down") {
                    download(model)
                }
                .labelStyle(.iconOnly)
                .disabled(capacityErrorMessage != nil || isCheckingNotForAllAudiences)
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
            }
        }
    }
}
