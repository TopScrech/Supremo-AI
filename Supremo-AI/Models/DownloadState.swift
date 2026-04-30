import Foundation

struct DownloadState: Codable, Equatable {
    var downloadedBytes = 0
    var totalBytes: Int?
    var bytesPerSecond: Double?
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
        
        let sizeText: String
        if let totalBytes {
            sizeText = "\(downloadedSizeDescription) of \(totalBytes.formatted(.byteCount(style: .file)))"
        } else {
            sizeText = downloadedBytes == 0 ? "Preparing" : downloadedSizeDescription
        }
        
        guard isDownloading, let speedDescription else { return sizeText }
        return "\(sizeText) at \(speedDescription)"
    }
    
    private var downloadedSizeDescription: String {
        Self.byteCountDescription(for: Double(downloadedBytes))
    }
    
    private var speedDescription: String? {
        guard let bytesPerSecond, bytesPerSecond > 0 else { return nil }
        return "\(Self.byteCountDescription(for: bytesPerSecond, fractionLength: 1))/s"
    }
    
    private static func byteCountDescription(for bytes: Double, fractionLength: Int = 2) -> String {
        let units = ["bytes", "KB", "MB", "GB", "TB"]
        var value = bytes
        var unitIndex = 0
        
        while value >= 1_000, unitIndex < units.count - 1 {
            value /= 1_000
            unitIndex += 1
        }
        
        let formattedValue = value.formatted(.number.precision(.fractionLength(fractionLength)))
        return "\(formattedValue) \(units[unitIndex])"
    }
}
