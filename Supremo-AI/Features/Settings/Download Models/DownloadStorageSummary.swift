import ScrechKit

struct DownloadStorageSummary: View {
    @State private var freeStorageDescription = "Checking"
    @State private var availableMemoryDescription = "Checking"
    
    var body: some View {
        Group {
            LabeledContentRow("Free Storage", systemImage: "internaldrive", value: freeStorageDescription)
            LabeledContentRow("Available VRAM", systemImage: "memorychip", value: availableMemoryDescription)
        }
        .task {
            updateStorageSummary()
        }
    }
    
    private func updateStorageSummary() {
        freeStorageDescription = formattedByteCount(StorageCapacity.availableForImportantUsage)
        availableMemoryDescription = formattedByteCount(StorageCapacity.availableMemory)
    }
    
    private func formattedByteCount(_ bytes: Int64?) -> String {
        guard let bytes else { return "Unavailable" }
        
        return bytes.formatted(.byteCount(style: .file))
    }
}
