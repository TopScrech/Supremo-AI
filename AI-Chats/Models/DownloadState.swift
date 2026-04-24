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
            return "\(downloadedBytes.formatted(.byteCount(style: .file))) of \(totalBytes.formatted(.byteCount(style: .file)))"
        }
        
        return downloadedBytes == 0 ? "Preparing" : downloadedBytes.formatted(.byteCount(style: .file))
    }
}
