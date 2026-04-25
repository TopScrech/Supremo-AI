import Foundation

enum StorageCapacity {
    static var availableForImportantUsage: Int64? {
        try? URL.documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    }
}
