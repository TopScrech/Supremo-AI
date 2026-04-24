import Foundation

struct DownloadState: Codable, Equatable {
    var downloadedBytes = 0
    var totalBytes: Int?
    var isDownloading = false
    var errorMessage: String?
    
    var progress: Double? {
        guard let totalBytes, totalBytes > 0 else { return nil }
        return min(Double(downloadedBytes) / Double(totalBytes), 1)
    }
    
    var statusText: String {
        if let errorMessage {
            return errorMessage
        }
        
        if let totalBytes {
            return "\(downloadedSizeDescription) of \(totalBytes.formatted(.byteCount(style: .file)))"
        }
        
        return downloadedBytes == 0 ? "Preparing" : downloadedSizeDescription
    }
    
    private var downloadedSizeDescription: String {
        let bytes = Double(downloadedBytes)
        let units = ["bytes", "KB", "MB", "GB", "TB"]
        var value = bytes
        var unitIndex = 0
        
        while value >= 1_000, unitIndex < units.count - 1 {
            value /= 1_000
            unitIndex += 1
        }
        
        let formattedValue = value.formatted(.number.precision(.fractionLength(2)))
        return "\(formattedValue) \(units[unitIndex])"
    }
}
