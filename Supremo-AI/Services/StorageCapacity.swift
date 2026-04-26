import Foundation
import Metal
import os

enum StorageCapacity {
    static var availableForImportantUsage: Int64? {
        try? URL.documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    }
    
    static var availableMemory: Int64 {
        Int64(os_proc_available_memory())
    }
}
