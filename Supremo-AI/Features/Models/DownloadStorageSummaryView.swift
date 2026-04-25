import ScrechKit

struct DownloadStorageSummaryView: View {
    @State private var freeStorageDescription = "Checking"
    
    var body: some View {
        LabeledContent {
            Text(freeStorageDescription)
                .monospacedDigit()
                .secondary()
        } label: {
            Label("Free Storage", systemImage: "internaldrive")
        }
        .task {
            updateFreeStorage()
        }
    }
    
    private func updateFreeStorage() {
        guard let bytes = StorageCapacity.availableForImportantUsage else {
            freeStorageDescription = "Unavailable"
            return
        }
        
        freeStorageDescription = bytes.formatted(.byteCount(style: .file))
    }
}
