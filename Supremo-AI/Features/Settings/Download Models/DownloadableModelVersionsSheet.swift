import ScrechKit

struct DownloadableModelVersionsSheet: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var versions: [DownloadableModel] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isNotForAllAudiencesAlertPresented = false
    @State private var isCheckingNotForAllAudiences = false
    @State private var pendingDownload: DownloadableModel?
    
    private let model: DownloadableModel
    
    init(_ model: DownloadableModel) {
        self.model = model
    }
    
    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else {
                ForEach(versions) {
                    DownloadableModelVersionRow($0, isCheckingNotForAllAudiences: isCheckingNotForAllAudiences) {
                        prepareDownload($0)
                    }
                }
            }
        }
        .navigationTitle(model.familyName)
        .scrollIndicators(.never)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", systemImage: "xmark") {
                    dismiss()
                }
            }
        }
        .task {
            await loadVersions()
        }
        .alert("Not for all audiences", isPresented: $isNotForAllAudiencesAlertPresented) {
            Button("Cancel", role: .cancel) {
                pendingDownload = nil
            }
            
            Button("Download", action: startPendingDownload)
        } message: {
            Text("This repository has been marked as containing sensitive content and may contain potentially harmful and sensitive information")
        }
    }
    
    private func loadVersions() async {
        guard versions.isEmpty, !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            versions = try await appModel.downloadableVersions(for: model)
            
            if versions.isEmpty {
                errorMessage = "No GGUF versions were found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func prepareDownload(_ model: DownloadableModel) {
        guard !isCheckingNotForAllAudiences else { return }
        
        pendingDownload = model
        isCheckingNotForAllAudiences = true
        
        Task {
            if await appModel.isMarkedNotForAllAudiences(model) {
                isNotForAllAudiencesAlertPresented = true
            } else {
                startDownload(model)
            }
            
            isCheckingNotForAllAudiences = false
        }
    }
    
    private func startPendingDownload() {
        guard let pendingDownload else { return }
        startDownload(pendingDownload)
        self.pendingDownload = nil
    }
    
    private func startDownload(_ model: DownloadableModel) {
        Task {
            await appModel.download(model)
        }
        
        dismiss()
    }
}
