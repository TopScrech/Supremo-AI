import Foundation

enum GGUFPromptTemplateReader {
    static let maximumMetadataBytes = 16 * 1024 * 1024

    static func promptTemplate(from url: URL) -> String? {
        guard let data = headerData(from: url) else { return nil }
        return promptTemplate(from: data)
    }

    static func promptTemplate(from data: Data) -> String? {
        do {
            var reader = GGUFMetadataReader(data)
            return try reader.promptTemplate()
        } catch {
            return nil
        }
    }

    private static func headerData(from url: URL) -> Data? {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer {
            try? fileHandle.close()
        }

        return try? fileHandle.read(upToCount: maximumMetadataBytes)
    }
}
