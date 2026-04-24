import Foundation
import Observation

@Observable
final class ChatAppModel {
    var chats: [ChatConfiguration] = []
    var selectedChatID: UUID?
    var modelFiles: [ModelFile] = []
    var downloadableModels = ModelCatalog.featured
    var downloadStates: [String: DownloadState] = [:]
    var isGenerating = false
    var statusMessage = ""
    var searchText = ""

    private let store = JSONFileStore()
    private let ragIndexer = RAGIndexer()
    private let inferenceEngine: LocalInferenceEngine = LLMFarmInferenceEngine()

    var isInferenceBackendAvailable: Bool {
        inferenceEngine.isAvailable
    }

    var selectedChat: ChatConfiguration? {
        guard let selectedChatID else { return nil }
        return chats.first { $0.id == selectedChatID }
    }

    var filteredChats: [ChatConfiguration] {
        guard !searchText.isEmpty else { return chats }
        return chats.filter {
            $0.title.localizedStandardContains(searchText) ||
            $0.modelName.localizedStandardContains(searchText)
        }
    }

    func load() {
        do {
            try store.ensureDirectories()
            chats = (try? store.load([ChatConfiguration].self, from: "chats.json")) ?? [ChatConfiguration.sample]
            modelFiles = (try? store.load([ModelFile].self, from: "models.json")) ?? []
            refreshModelFilesFromDisk()
            selectedChatID = chats.first?.id
            try save()
        } catch {
            statusMessage = error.localizedDescription
            chats = [ChatConfiguration.sample]
            selectedChatID = chats.first?.id
        }
    }

    func save() throws {
        try store.save(chats, to: "chats.json")
        try store.save(modelFiles.filter { $0.isPartialDownload != true }, to: "models.json")
    }

    func createChat() {
        let fallbackModel = modelFiles.first { $0.isAvailableLocally }
        let chat = ChatConfiguration(title: "New Chat", modelName: fallbackModel?.displayName ?? "No model selected", modelFileID: fallbackModel?.id)
        chats.insert(chat, at: 0)
        selectedChatID = chat.id
        persistStatus()
    }

    func duplicateChat(_ chat: ChatConfiguration) {
        var copy = chat
        copy.id = UUID()
        copy.title = "\(chat.title) Copy"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        chats.insert(copy, at: 0)
        selectedChatID = copy.id
        persistStatus()
    }

    func deleteChat(_ chat: ChatConfiguration) {
        let wasSelected = selectedChatID == chat.id
        chats.removeAll { $0.id == chat.id }
        if wasSelected {
            selectedChatID = nil
        }
        persistStatus()
    }

    func deleteChats(at offsets: IndexSet) {
        let chatsToDelete = offsets.compactMap { filteredChats.indices.contains($0) ? filteredChats[$0] : nil }
        chatsToDelete.forEach(deleteChat)
    }

    func updateChat(_ chat: ChatConfiguration) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        var updated = chat
        updated.updatedAt = Date()
        chats[index] = updated
        selectedChatID = updated.id
        persistStatus()
    }

    func isModelReady(for chat: ChatConfiguration) -> Bool {
        guard let modelFileID = chat.modelFileID else { return false }
        return modelFiles.contains { $0.id == modelFileID && $0.isAvailableLocally }
    }

    func canRunChat(_ chat: ChatConfiguration) -> Bool {
        isModelReady(for: chat) && isInferenceBackendAvailable
    }

    func assignModel(_ model: ModelFile, to chat: ChatConfiguration) {
        guard model.isAvailableLocally else {
            statusMessage = "Finish downloading \(model.fileName) before using it"
            return
        }

        var updated = chat
        updated.modelFileID = model.id
        updated.modelName = model.displayName
        updated.settings.inference = model.family
        updateChat(updated)
    }

    func deleteModel(_ model: ModelFile) {
        if let localURL = model.localURL, FileManager.default.fileExists(atPath: localURL.path()) {
            try? FileManager.default.removeItem(at: localURL)
        }

        modelFiles.removeAll { $0.id == model.id }
        for index in chats.indices where chats[index].modelFileID == model.id {
            let fallbackModel = modelFiles.first { $0.isAvailableLocally }
            chats[index].modelFileID = fallbackModel?.id
            chats[index].modelName = fallbackModel?.displayName ?? "No model selected"
            chats[index].updatedAt = Date()
        }

        statusMessage = "Deleted \(model.fileName)"
        persistStatus()
    }

    func clearMessages(in chat: ChatConfiguration) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index].messages.removeAll()
        chats[index].updatedAt = Date()
        persistStatus()
    }

    func sendPrompt(_ prompt: String, useRAG: Bool) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, let chatIndex = currentChatIndex else { return }
        guard isModelReady(for: chats[chatIndex]) else {
            statusMessage = "Install or select a model before chatting"
            return
        }
        guard isInferenceBackendAvailable else {
            statusMessage = InferenceEngineError.backendUnavailable.localizedDescription
            return
        }

        let userMessage = ChatMessage(role: .user, text: trimmedPrompt)
        chats[chatIndex].messages.append(userMessage)
        chats[chatIndex].updatedAt = Date()
        isGenerating = true
        persistStatus()

        let chatSnapshot = chats[chatIndex]
        var generationChat = chatSnapshot
        generationChat.modelFileURL = modelFiles.first { $0.id == chatSnapshot.modelFileID }?.localURL
        let ragContext = useRAG || chatSnapshot.settings.rag.isEnabled ? ragIndexer.rankedContext(
            for: trimmedPrompt,
            documents: chatSnapshot.documents,
            maxCount: chatSnapshot.settings.rag.maxAnswerCount
        ) : []

        do {
            let response = try await inferenceEngine.response(for: trimmedPrompt, chat: generationChat, context: ragContext)
            guard let updatedIndex = currentChatIndex else { return }
            if !ragContext.isEmpty {
                let contextText = ragContext.map { "\($0.title): \($0.text)" }.joined(separator: "\n\n")
                chats[updatedIndex].messages.append(ChatMessage(role: .rag, text: contextText))
            }
            chats[updatedIndex].messages.append(ChatMessage(role: .assistant, text: response))
            chats[updatedIndex].updatedAt = Date()
            statusMessage = "Generated preview response"
        } catch {
            guard let updatedIndex = currentChatIndex else { return }
            chats[updatedIndex].messages.append(ChatMessage(role: .assistant, text: error.localizedDescription))
            statusMessage = error.localizedDescription
        }

        isGenerating = false
        persistStatus()
    }

    func addDocument(title: String, text: String, to chat: ChatConfiguration) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index].documents.append(RAGDocument(title: title, text: text, sourceURL: nil))
        chats[index].updatedAt = Date()
        persistStatus()
    }

    func removeDocument(_ document: RAGDocument, from chat: ChatConfiguration) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chats[index].documents.removeAll { $0.id == document.id }
        chats[index].updatedAt = Date()
        persistStatus()
    }

    func importModel(from url: URL) {
        let destination = store.modelsURL.appending(path: url.lastPathComponent)
        do {
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            try store.ensureDirectories()
            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: url, to: destination)
            modelFiles.removeAll { $0.fileName == url.lastPathComponent || $0.fileName == "\(url.lastPathComponent).download" }
            let model = ModelFile(displayName: url.deletingPathExtension().lastPathComponent, fileName: url.lastPathComponent, localURL: destination, remoteURL: nil, quantization: "Local", family: .llama, sizeDescription: "Imported")
            modelFiles.append(model)
            if let selectedChat, selectedChat.modelFileID == nil {
                assignModel(model, to: selectedChat)
            }
            statusMessage = "Imported \(model.fileName)"
            persistStatus()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func registerDownloadedModel(_ downloadableModel: DownloadableModel, localURL: URL) {
        modelFiles.removeAll { $0.fileName == downloadableModel.fileName || $0.fileName == "\(downloadableModel.fileName).download" }
        let model = ModelFile(displayName: downloadableModel.familyName, fileName: downloadableModel.fileName, localURL: localURL, remoteURL: downloadableModel.url, quantization: downloadableModel.quantization, family: downloadableModel.inference, sizeDescription: downloadableModel.sizeDescription)
        modelFiles.append(model)
        if let selectedChat, selectedChat.modelFileID == nil {
            assignModel(model, to: selectedChat)
        }
        statusMessage = "Added \(downloadableModel.fileName)"
        persistStatus()
    }

    func download(_ model: DownloadableModel) async {
        guard downloadStates[model.fileName]?.isDownloading != true else { return }

        let destination = store.modelsURL.appending(path: model.fileName)
        let partialDestination = store.modelsURL.appending(path: "\(model.fileName).download")

        do {
            statusMessage = "Downloading \(model.fileName)"
            downloadStates[model.fileName] = DownloadState(totalBytes: model.sizeBytes, isDownloading: true)
            try store.ensureDirectories()

            if FileManager.default.fileExists(atPath: partialDestination.path()) {
                try FileManager.default.removeItem(at: partialDestination)
            }

            FileManager.default.createFile(atPath: partialDestination.path(), contents: nil)
            refreshModelFilesFromDisk()
            try await downloadFile(from: model.url, to: partialDestination, modelFileName: model.fileName)

            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: partialDestination, to: destination)
            downloadStates[model.fileName]?.isDownloading = false
            registerDownloadedModel(model, localURL: destination)
        } catch {
            refreshModelFilesFromDisk()
            downloadStates[model.fileName] = DownloadState(isDownloading: false, errorMessage: error.localizedDescription)
            statusMessage = error.localizedDescription
        }
    }

    private func downloadFile(from url: URL, to destination: URL, modelFileName: String) async throws {
        let delegate = ModelDownloadDelegate(destination: destination) { [weak self] downloadedBytes, totalBytes in
            Task { @MainActor in
                self?.downloadStates[modelFileName]?.downloadedBytes = downloadedBytes
                self?.downloadStates[modelFileName]?.totalBytes = totalBytes
            }
        }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer {
            session.invalidateAndCancel()
        }

        try await delegate.download(from: url, using: session)
    }

    func applyTemplate(_ template: ChatSettingsTemplate, to chat: ChatConfiguration) {
        var updated = chat
        updated.settings.modelSettingsTemplate = template.name
        updated.settings.inference = template.inference
        updated.settings.prediction.contextLength = template.contextLength
        updated.settings.prediction.batchSize = template.batchSize
        updated.settings.prediction.useMetal = template.useMetal
        updated.settings.sampling.temperature = template.temperature
        updated.settings.sampling.topK = template.topK
        updated.settings.sampling.topP = template.topP
        updated.settings.prompt.promptFormat = template.promptFormat
        updateChat(updated)
    }

    func responseForShortcut(prompt: String, chatID: UUID?) async -> String {
        if let chatID {
            selectedChatID = chatID
        }
        await sendPrompt(prompt, useRAG: true)
        return selectedChat?.messages.last?.text ?? ""
    }

    private var currentChatIndex: Int? {
        guard let selectedChatID else { return chats.indices.first }
        return chats.firstIndex { $0.id == selectedChatID }
    }

    private func refreshModelFilesFromDisk() {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: store.modelsURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let discovered = urls
            .filter { $0.pathExtension == "gguf" || $0.lastPathComponent.hasSuffix(".gguf.download") }
            .map(discoveredModelFile)

        modelFiles.removeAll { model in
            guard let localURL = model.localURL else { return false }
            return !FileManager.default.fileExists(atPath: localURL.path())
        }

        modelFiles.removeAll { $0.isPartialDownload == true }

        for model in discovered where !modelFiles.contains(where: { $0.localURL?.path() == model.localURL?.path() || $0.fileName == model.fileName }) {
            modelFiles.append(model)
        }
    }

    private func discoveredModelFile(from url: URL) -> ModelFile {
        let isPartialDownload = url.lastPathComponent.hasSuffix(".download")
        let completeFileName = isPartialDownload ? String(url.lastPathComponent.dropLast(".download".count)) : url.lastPathComponent
        let displayName = URL(filePath: completeFileName).deletingPathExtension().lastPathComponent
        let catalogModel = downloadableModels.first { $0.fileName == completeFileName }
        let fileSize = fileSizeDescription(for: url)

        return ModelFile(
            displayName: catalogModel?.familyName ?? displayName,
            fileName: url.lastPathComponent,
            localURL: url,
            remoteURL: catalogModel?.url,
            quantization: isPartialDownload ? "Partial" : catalogModel?.quantization ?? "Local",
            family: catalogModel?.inference ?? inferredInferenceKind(from: completeFileName),
            sizeDescription: isPartialDownload ? "\(fileSize) downloaded" : fileSize,
            isPartialDownload: isPartialDownload
        )
    }

    private func fileSizeDescription(for url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values?.fileSize else { return "Unknown size" }
        return fileSize.formatted(.byteCount(style: .file))
    }

    private func inferredInferenceKind(from fileName: String) -> InferenceKind {
        let lowercasedFileName = fileName.lowercased()
        if lowercasedFileName.localizedStandardContains("gemma") { return .gemma }
        if lowercasedFileName.localizedStandardContains("qwen") { return .qwen }
        if lowercasedFileName.localizedStandardContains("phi") { return .phi }
        if lowercasedFileName.localizedStandardContains("deepseek") { return .deepseek }
        if lowercasedFileName.localizedStandardContains("mixtral") { return .mixtral }
        if lowercasedFileName.localizedStandardContains("llava") { return .llava }
        if lowercasedFileName.localizedStandardContains("moondream") { return .moondream }
        if lowercasedFileName.localizedStandardContains("starcoder") { return .starcoder }
        if lowercasedFileName.localizedStandardContains("falcon") { return .falcon }
        return .llama
    }

    private func persistStatus() {
        do {
            try save()
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

private final class ModelDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let destination: URL
    private let progressHandler: @Sendable (Int, Int?) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private var didFinishDownloading = false

    init(destination: URL, progressHandler: @escaping @Sendable (Int, Int?) -> Void) {
        self.destination = destination
        self.progressHandler = progressHandler
    }

    func download(from url: URL, using session: URLSession) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.downloadTask(with: url).resume()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let totalBytes = totalBytesExpectedToWrite > 0 ? Int(totalBytesExpectedToWrite) : nil
        progressHandler(Int(totalBytesWritten), totalBytes)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            didFinishDownloading = true
            continuation?.resume()
            continuation = nil
        } catch {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error, !didFinishDownloading else { return }
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
