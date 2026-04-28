import Foundation

struct ShortcutModelLibrary {
    private let store = JSONFileStore()

    func localModels() throws -> [ModelFile] {
        try store.ensureDirectories()
        var modelFiles = (try? store.load([ModelFile].self, from: "models.json")) ?? []
        refreshModelFilesFromDisk(&modelFiles)
        return modelFiles.filter { $0.isAvailableLocally }
    }

    func selectedModel(for chat: ChatConfiguration, preferredModelID: UUID?, in modelFiles: [ModelFile]) -> ModelFile? {
        if let preferredModelID,
           let preferredModel = modelFiles.first(where: { $0.id == preferredModelID && $0.isAvailableLocally }) {
            return preferredModel
        }

        if let modelFileID = chat.modelFileID,
           let selectedModel = modelFiles.first(where: { $0.id == modelFileID && $0.isAvailableLocally }) {
            return selectedModel
        }

        return modelFiles.first { $0.isAvailableLocally }
    }

    private func refreshModelFilesFromDisk(_ modelFiles: inout [ModelFile]) {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: store.modelsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let discoveredModels = urls
            .filter { $0.pathExtension == "gguf" || $0.lastPathComponent.hasSuffix(".gguf.download") }
            .map(discoveredModel)

        modelFiles.removeAll { model in
            guard let localURL = model.localURL else { return false }
            return !FileManager.default.fileExists(atPath: localURL.path())
        }

        modelFiles.removeAll { $0.isPartialDownload == true }

        for model in discoveredModels where !modelFiles.contains(where: { $0.localURL?.path() == model.localURL?.path() || $0.fileName == model.fileName }) {
            modelFiles.append(model)
        }
    }

    private func discoveredModel(from url: URL) -> ModelFile {
        let isPartialDownload = url.lastPathComponent.hasSuffix(".download")
        let completeFileName = isPartialDownload ? String(url.lastPathComponent.dropLast(".download".count)) : url.lastPathComponent
        let displayName = URL(filePath: completeFileName).deletingPathExtension().lastPathComponent
        let catalogModel = ModelCatalog.featured.first { $0.fileName == completeFileName }

        return ModelFile(
            displayName: catalogModel?.familyName ?? displayName,
            fileName: url.lastPathComponent,
            localURL: url,
            remoteURL: catalogModel?.url,
            quantization: isPartialDownload ? "Partial" : catalogModel?.quantization ?? ModelQuantization.value(from: completeFileName, fallback: "Local"),
            family: catalogModel?.inference ?? inferredInferenceKind(from: completeFileName),
            isPartialDownload: isPartialDownload
        )
    }

    private func inferredInferenceKind(from fileName: String) -> InferenceKind {
        let lowercasedFileName = fileName.lowercased()
        if lowercasedFileName.localizedStandardContains("gemma") { return .gemma }
        if lowercasedFileName.localizedStandardContains("deepseek") { return .deepseek }
        if lowercasedFileName.localizedStandardContains("qwen") { return .qwen }
        if lowercasedFileName.localizedStandardContains("baichuan") { return .baichuan }
        if lowercasedFileName.localizedStandardContains("phi") { return .phi }
        return .llama
    }
}
