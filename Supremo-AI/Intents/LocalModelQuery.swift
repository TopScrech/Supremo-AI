import AppIntents
import Foundation

struct LocalModelQuery: EntityQuery, EntityStringQuery {
    func entities(for identifiers: [UUID]) async throws -> [LocalModelEntity] {
        try await localModels().filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [LocalModelEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return try await localModels().filter {
            $0.displayName.localizedStandardContains(query) ||
            $0.fileName.localizedStandardContains(query) ||
            $0.quantization.localizedStandardContains(query)
        }
    }

    func suggestedEntities() async throws -> [LocalModelEntity] {
        try await localModels()
    }

    private func localModels() async throws -> [LocalModelEntity] {
        try await ShortcutModelLibrary()
            .localModels()
            .map(LocalModelEntity.init)
    }
}
