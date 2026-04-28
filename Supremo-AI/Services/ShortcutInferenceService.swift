import Foundation

struct ShortcutInferenceService {
    private let store = JSONFileStore()
    private let inferenceEngine: LocalInferenceEngine = SwiftLlamaInferenceEngine()
    private let ragIndexer = RAGIndexer()

    func response(prompt: String) async throws -> String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw ShortcutInferenceError.emptyPrompt
        }

        try store.ensureDirectories()
        var chats = try store.load([ChatConfiguration].self, from: "chats.json")
        var modelFiles = (try? store.load([ModelFile].self, from: "models.json")) ?? []
        refreshModelFilesFromDisk(&modelFiles)

        guard let chatIndex = chats.indices.first else {
            throw ShortcutInferenceError.missingChat
        }

        guard let model = selectedModel(for: chats[chatIndex], in: modelFiles),
              let modelURL = model.localURL,
              FileManager.default.fileExists(atPath: modelURL.path()) else {
            throw ShortcutInferenceError.missingModel
        }

        var chat = chats[chatIndex]
        chat.modelFileID = model.id
        chat.modelName = model.displayName
        chat.modelFileURL = modelURL

        let context = chat.settings.rag.isEnabled ? ragIndexer.rankedContext(
            for: trimmedPrompt,
            documents: chat.documents,
            maxCount: chat.settings.rag.maxAnswerCount
        ) : []

        let response = try await inferenceEngine.response(for: trimmedPrompt, chat: chat, context: context)

        chats[chatIndex].modelFileID = model.id
        chats[chatIndex].modelName = model.displayName
        chats[chatIndex].messages.append(ChatMessage(role: .user, text: trimmedPrompt))
        if !context.isEmpty {
            let contextText = context.map { "\($0.title): \($0.text)" }.joined(separator: "\n\n")
            chats[chatIndex].messages.append(ChatMessage(role: .rag, text: contextText))
        }
        chats[chatIndex].messages.append(ChatMessage(role: .assistant, text: response))
        chats[chatIndex].updatedAt = Date()

        try store.save(chats, to: "chats.json")
        try store.save(modelFiles.filter { $0.isPartialDownload != true }, to: "models.json")

        return response
    }

    private func selectedModel(for chat: ChatConfiguration, in modelFiles: [ModelFile]) -> ModelFile? {
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
            quantization: isPartialDownload ? "Partial" : catalogModel?.quantization ?? "Local",
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
