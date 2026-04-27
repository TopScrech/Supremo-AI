import Foundation
import Observation
import OSLog

@Observable
final class ChatAppModel {
    var chats: [ChatConfiguration] = []
    var selectedChatID: UUID?
    var modelFiles: [ModelFile] = []
    var downloadableModels = ModelCatalog.featured
    var downloadStates: [String: DownloadState] = [:]
    var modelInitializationStates: [UUID: ModelInitializationState] = [:]
    var modelInitializationMessages: [UUID: String] = [:]
    var isGenerating = false
    var searchText = ""

    private let store = JSONFileStore()
    private let ragIndexer = RAGIndexer()
    private let remoteFileSizeResolver = RemoteFileSizeResolver()
    private let inferenceEngine: LocalInferenceEngine = SwiftLlamaInferenceEngine()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AI-Chats", category: "ChatAppModel")
    private var refreshingDownloadSizes = Set<String>()
    private var typingTask: Task<Void, Never>?

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

    var localModelsSizeDescription: String {
        let totalBytes = modelFiles.reduce(0) { total, model in
            guard let localURL = model.localURL else { return total }
            return total + fileSize(for: localURL)
        }

        return totalBytes.formatted(.byteCount(style: .file))
    }

    var downloadableModelFamilies: [DownloadableModelFamily] {
        var families: [DownloadableModelFamily] = []

        for model in downloadableModels {
            if let index = families.firstIndex(where: { $0.name == model.familyDisplayName }) {
                families[index].models.append(model)
            } else {
                families.append(DownloadableModelFamily(name: model.familyDisplayName, models: [model]))
            }
        }

        return families
    }

    func canDownload(_ model: DownloadableModel) -> Bool {
        downloadCapacityErrorMessage(for: model) == nil
    }

    func downloadCapacityErrorMessage(for model: DownloadableModel) -> String? {
        guard
            let remainingBytes = remainingDownloadBytes(for: model),
            let availableStorageBytes = StorageCapacity.availableForImportantUsage
        else {
            return nil
        }

        if remainingBytes > availableStorageBytes {
            return "Too large for the available storage"
        }

        guard let modelSizeBytes = model.sizeBytes else { return nil }
        let availableMemoryBytes = StorageCapacity.availableMemory

        if modelSizeBytes > availableMemoryBytes {
            return "Too large for the available VRAM"
        }

        return nil
    }

    func refreshDownloadSizes() async {
        for model in downloadableModels where model.sizeBytes == nil {
            await refreshDownloadSize(for: model)
        }
    }

    func load() {
        do {
            try store.ensureDirectories()
            chats = (try? store.load([ChatConfiguration].self, from: "chats.json")) ?? [ChatConfiguration.sample]
            finishPersistedTypingAnimations()
            modelFiles = (try? store.load([ModelFile].self, from: "models.json")) ?? []
            refreshModelFilesFromDisk()
            selectedChatID = chats.first?.id
            try save()
        } catch {
            logger.error("\(error.localizedDescription, privacy: .public)")
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

    func renameChat(_ chat: ChatConfiguration, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }

        chats[index].title = trimmedTitle
        chats[index].updatedAt = Date()
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
        let existingChat = chats[index]
        var updated = chat
        updated.updatedAt = Date()
        chats[index] = updated
        selectedChatID = updated.id
        if existingChat.modelFileID != updated.modelFileID || existingChat.settings != updated.settings {
            modelInitializationStates[updated.id] = .idle
            modelInitializationMessages[updated.id] = nil
        }
        persistStatus()
    }

    func isModelReady(for chat: ChatConfiguration) -> Bool {
        guard let modelFileID = chat.modelFileID else { return false }
        return modelFiles.contains { $0.id == modelFileID && $0.isAvailableLocally }
    }

    func canRunChat(_ chat: ChatConfiguration) -> Bool {
        isModelReady(for: chat) && isInferenceBackendAvailable && isModelInitialized(for: chat)
    }

    func isModelInitialized(for chat: ChatConfiguration) -> Bool {
        modelInitializationStates[chat.id] == .ready
    }

    func modelInitializationState(for chat: ChatConfiguration) -> ModelInitializationState {
        modelInitializationStates[chat.id] ?? .idle
    }

    func initializeModel(for chat: ChatConfiguration) async {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        guard isModelReady(for: chats[chatIndex]), isInferenceBackendAvailable else { return }

        modelInitializationStates[chat.id] = .initializing
        modelInitializationMessages[chat.id] = nil

        var initializationChat = chats[chatIndex]
        initializationChat.modelFileURL = modelFiles.first { $0.id == initializationChat.modelFileID }?.localURL

        do {
            try await inferenceEngine.prepare(chat: initializationChat)
            modelInitializationStates[chat.id] = .ready
            modelInitializationMessages[chat.id] = nil
            logger.info("Initialized model \(initializationChat.modelName, privacy: .public)")
        } catch {
            modelInitializationStates[chat.id] = .failed
            modelInitializationMessages[chat.id] = error.localizedDescription
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
    }

    func ejectModel(for chat: ChatConfiguration) async {
        var ejectionChat = chat
        ejectionChat.modelFileURL = modelFiles.first { $0.id == chat.modelFileID }?.localURL
        await inferenceEngine.eject(chat: ejectionChat)
        modelInitializationStates[chat.id] = .idle
        modelInitializationMessages[chat.id] = nil
        logger.info("Ejected model \(chat.modelName, privacy: .public)")
    }

    func assignModel(_ model: ModelFile, to chat: ChatConfiguration) {
        guard model.isAvailableLocally else {
            logger.info("Finish downloading \(model.fileName, privacy: .public) before using it")
            return
        }

        var updated = chat
        updated.modelFileID = model.id
        updated.modelName = model.displayName
        updated.applyAutomaticTemplate(for: model)
        modelInitializationStates[chat.id] = .idle
        modelInitializationMessages[chat.id] = nil
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

        logger.info("Deleted \(model.fileName, privacy: .public)")
        persistStatus()
    }

    func clearMessages(in chat: ChatConfiguration) {
        guard let index = chats.firstIndex(where: { $0.id == chat.id }) else { return }
        typingTask?.cancel()
        typingTask = nil
        chats[index].messages.removeAll()
        chats[index].updatedAt = Date()
        persistStatus()
    }

    func sendPrompt(_ prompt: String, useRAG: Bool) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, let chatIndex = currentChatIndex else { return }
        guard isModelReady(for: chats[chatIndex]) else {
            logger.info("Install or select a model before chatting")
            return
        }
        guard isInferenceBackendAvailable else {
            logger.error("\(InferenceEngineError.backendUnavailable.localizedDescription, privacy: .public)")
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
            if !ragContext.isEmpty {
                let contextText = ragContext.map { "\($0.title): \($0.text)" }.joined(separator: "\n\n")
                chats[chatIndex].messages.append(ChatMessage(role: .rag, text: contextText))
            }

            let assistantMessage = ChatMessage(role: .assistant, text: "")
            chats[chatIndex].messages.append(assistantMessage)
            chats[chatIndex].updatedAt = Date()

            let responseStream = try await inferenceEngine.responseStream(for: trimmedPrompt, chat: generationChat, context: ragContext)
            for try await partialResponse in responseStream {
                updateMessageTarget(assistantMessage.id, in: chatSnapshot.id, text: partialResponse)
            }

            updateChatTimestamp(chatSnapshot.id)
            logger.info("Generated streaming response")
        } catch {
            updateLatestAssistantMessage(in: chatSnapshot.id, fallbackText: error.localizedDescription)
            logger.error("\(error.localizedDescription, privacy: .public)")
        }

        isGenerating = false
        persistStatus()
    }

    private func updateMessageTarget(_ messageID: UUID, in chatID: UUID, text: String) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatID }),
              let messageIndex = chats[chatIndex].messages.firstIndex(where: { $0.id == messageID }) else { return }

        chats[chatIndex].messages[messageIndex].targetText = text
        chats[chatIndex].updatedAt = Date()
        startTypingTaskIfNeeded()
    }

    private func updateLatestAssistantMessage(in chatID: UUID, fallbackText: String) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatID }) else { return }

        if let messageIndex = chats[chatIndex].messages.lastIndex(where: { $0.role == .assistant }) {
            let existingText = chats[chatIndex].messages[messageIndex].text
            chats[chatIndex].messages[messageIndex].targetText = existingText.isEmpty ? fallbackText : existingText
            startTypingTaskIfNeeded()
        } else {
            chats[chatIndex].messages.append(ChatMessage(role: .assistant, text: fallbackText))
        }
        chats[chatIndex].updatedAt = Date()
    }

    private func updateChatTimestamp(_ chatID: UUID) {
        guard let chatIndex = chats.firstIndex(where: { $0.id == chatID }) else { return }
        chats[chatIndex].updatedAt = Date()
    }

    private func startTypingTaskIfNeeded() {
        guard typingTask == nil else { return }

        typingTask = Task { [weak self] in
            await self?.runTypingLoop()
        }
    }

    private func runTypingLoop() async {
        while !Task.isCancelled {
            guard let pendingMessageIndex = pendingTypingMessageIndex else {
                break
            }

            let chatIndex = pendingMessageIndex.chat
            let messageIndex = pendingMessageIndex.message
            let message = chats[chatIndex].messages[messageIndex]
            let targetText = message.targetText ?? message.text

            if message.text == targetText {
                if !isGenerating {
                    break
                }

                do {
                    try await Task.sleep(for: .milliseconds(40))
                } catch {
                    break
                }

                continue
            }

            if !targetText.hasPrefix(message.text) {
                let commonPrefixCount = commonPrefixCount(between: message.text, and: targetText)
                chats[chatIndex].messages[messageIndex].text = String(targetText.prefix(commonPrefixCount))
                continue
            }

            let remainingCount = targetText.count - message.text.count
            let step = switch remainingCount {
            case 25...: 4
            case 10...24: 2
            default: 1
            }

            chats[chatIndex].messages[messageIndex].text = String(targetText.prefix(min(message.text.count + step, targetText.count)))
            chats[chatIndex].updatedAt = Date()

            do {
                try await Task.sleep(for: .milliseconds(18))
            } catch {
                break
            }
        }

        typingTask = nil
        finishPersistedTypingAnimations()
        persistStatus()
    }

    private func commonPrefixCount(between lhs: String, and rhs: String) -> Int {
        zip(lhs, rhs)
            .prefix { $0 == $1 }
            .count
    }

    private var pendingTypingMessageIndex: (chat: Int, message: Int)? {
        for chatIndex in chats.indices {
            if let messageIndex = chats[chatIndex].messages.lastIndex(where: {
                $0.role == .assistant && $0.text != ($0.targetText ?? $0.text)
            }) {
                return (chatIndex, messageIndex)
            }
        }

        if isGenerating {
            for chatIndex in chats.indices {
                if let messageIndex = chats[chatIndex].messages.lastIndex(where: { $0.role == .assistant }) {
                    return (chatIndex, messageIndex)
                }
            }
        }

        return nil
    }

    private func finishPersistedTypingAnimations() {
        for chatIndex in chats.indices {
            for messageIndex in chats[chatIndex].messages.indices {
                if let targetText = chats[chatIndex].messages[messageIndex].targetText {
                    chats[chatIndex].messages[messageIndex].text = targetText
                    chats[chatIndex].messages[messageIndex].targetText = nil
                }
            }
        }
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
            let model = ModelFile(displayName: url.deletingPathExtension().lastPathComponent, fileName: url.lastPathComponent, localURL: destination, remoteURL: nil, quantization: "Local", family: .llama)
            modelFiles.append(model)
            if let selectedChat, selectedChat.modelFileID == nil {
                assignModel(model, to: selectedChat)
            }
            logger.info("Imported \(model.fileName, privacy: .public)")
            persistStatus()
        } catch {
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
    }

    func registerDownloadedModel(_ downloadableModel: DownloadableModel, localURL: URL) {
        modelFiles.removeAll { $0.fileName == downloadableModel.fileName || $0.fileName == "\(downloadableModel.fileName).download" }
        let model = ModelFile(displayName: downloadableModel.familyName, fileName: downloadableModel.fileName, localURL: localURL, remoteURL: downloadableModel.url, quantization: downloadableModel.quantization, family: downloadableModel.inference)
        modelFiles.append(model)
        if let selectedChat, selectedChat.modelFileID == nil {
            assignModel(model, to: selectedChat)
        }
        logger.info("Added \(downloadableModel.fileName, privacy: .public)")
        persistStatus()
    }

    func download(_ model: DownloadableModel) async {
        guard downloadStates[model.fileName]?.isDownloading != true else { return }

        await refreshDownloadSize(for: model)
        let currentModel = downloadableModels.first { $0.fileName == model.fileName } ?? model

        let destination = store.modelsURL.appending(path: currentModel.fileName)
        let partialDestination = store.modelsURL.appending(path: "\(currentModel.fileName).download")

        do {
            logger.info("Downloading \(currentModel.fileName, privacy: .public)")
            try store.ensureDirectories()
            let existingBytes = fileSize(for: partialDestination)
            if let errorMessage = downloadCapacityErrorMessage(for: currentModel) {
                downloadStates[currentModel.fileName] = DownloadState(downloadedBytes: existingBytes, totalBytes: currentModel.sizeBytes, isDownloading: false, errorMessage: errorMessage)
                return
            }

            downloadStates[currentModel.fileName] = DownloadState(downloadedBytes: existingBytes, totalBytes: currentModel.sizeBytes, isDownloading: true)

            createPartialDownloadFileIfNeeded(at: partialDestination)
            refreshModelFilesFromDisk()
            try await downloadFile(from: currentModel.url, to: partialDestination, modelFileName: currentModel.fileName)

            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: partialDestination, to: destination)
            downloadStates[currentModel.fileName]?.isDownloading = false
            registerDownloadedModel(currentModel, localURL: destination)
        } catch {
            refreshModelFilesFromDisk()
            downloadStates[currentModel.fileName] = DownloadState(downloadedBytes: fileSize(for: partialDestination), totalBytes: currentModel.sizeBytes, isDownloading: false, errorMessage: error.localizedDescription)
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
    }

    func continueDownload(_ model: ModelFile) async {
        guard let downloadableModel = downloadableModel(forPartialDownload: model) else { return }
        await download(downloadableModel)
    }

    private func downloadFile(from url: URL, to destination: URL, modelFileName: String) async throws {
        let existingBytes = fileSize(for: destination)
        var request = URLRequest(url: url)
        if existingBytes > 0 {
            request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
        }

        let delegate = ModelDataDownloadDelegate(destination: destination, existingBytes: existingBytes) { [weak self] downloadedBytes, totalBytes in
            Task { @MainActor [weak self] in
                self?.updateDownloadProgress(modelFileName: modelFileName, downloadedBytes: downloadedBytes, totalBytes: totalBytes)
            }
        }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer {
            session.invalidateAndCancel()
        }

        try await delegate.download(request, using: session)
    }

    private func updateDownloadProgress(modelFileName: String, downloadedBytes: Int, totalBytes: Int?) {
        downloadStates[modelFileName]?.downloadedBytes = downloadedBytes
        downloadStates[modelFileName]?.totalBytes = totalBytes
    }

    private func downloadableModel(forPartialDownload model: ModelFile) -> DownloadableModel? {
        let downloadFileSuffix = ".download"
        let fileName = model.fileName.hasSuffix(downloadFileSuffix) ? String(model.fileName.dropLast(downloadFileSuffix.count)) : model.fileName

        if let catalogModel = downloadableModels.first(where: { $0.fileName == fileName }) {
            return catalogModel
        }

        guard let remoteURL = model.remoteURL else { return nil }
        return DownloadableModel(
            familyName: model.displayName,
            fileName: fileName,
            url: remoteURL,
            quantization: model.quantization,
            sizeBytes: nil,
            inference: model.family
        )
    }

    private func createPartialDownloadFileIfNeeded(at url: URL) {
        guard !FileManager.default.fileExists(atPath: url.path()) else { return }
        FileManager.default.createFile(atPath: url.path(), contents: nil)
    }

    private func refreshDownloadSize(for model: DownloadableModel) async {
        guard model.sizeBytes == nil,
              refreshingDownloadSizes.contains(model.fileName) == false else { return }

        refreshingDownloadSizes.insert(model.fileName)
        defer {
            refreshingDownloadSizes.remove(model.fileName)
        }

        do {
            let sizeBytes = try await remoteFileSizeResolver.sizeBytes(for: model.url)
            guard let index = downloadableModels.firstIndex(where: { $0.fileName == model.fileName }) else { return }
            downloadableModels[index].sizeBytes = sizeBytes
        } catch {
            logger.error("Unable to fetch size for \(model.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    private func remainingDownloadBytes(for model: DownloadableModel) -> Int64? {
        let currentModel = downloadableModels.first { $0.fileName == model.fileName } ?? model
        guard let sizeBytes = currentModel.sizeBytes else { return nil }
        let partialDestination = store.modelsURL.appending(path: "\(model.fileName).download")
        let existingBytes = fileSize(for: partialDestination)
        return Int64(max(sizeBytes - existingBytes, 0))
    }

    private func fileSize(for url: URL) -> Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path()),
              let fileSize = attributes[.size] as? NSNumber else { return 0 }
        return fileSize.intValue
    }

    func applyTemplate(_ template: ChatSettingsTemplate, to chat: ChatConfiguration) {
        var updated = chat
        updated.applyTemplate(template)
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
        if lowercasedFileName.localizedStandardContains("phi") { return .phi }
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
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
    }
}

private final class ModelDataDownloadDelegate: NSObject, @preconcurrency URLSessionDataDelegate {
    private let destination: URL
    private let existingBytes: Int
    private let progressHandler: @Sendable (Int, Int?) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private var fileHandle: FileHandle?
    private var downloadedBytes = 0
    private var totalBytes: Int?

    init(destination: URL, existingBytes: Int, progressHandler: @escaping @Sendable (Int, Int?) -> Void) {
        self.destination = destination
        self.existingBytes = existingBytes
        self.progressHandler = progressHandler
    }

    func download(_ request: URLRequest, using session: URLSession) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.dataTask(with: request).resume()
        }
    }

    @MainActor
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        do {
            let effectiveExistingBytes = dataTask.responseSupportsPartialContent ? existingBytes : 0

            if effectiveExistingBytes == 0 {
                FileManager.default.createFile(atPath: destination.path(), contents: nil)
            }

            let handle = try FileHandle(forWritingTo: destination)

            if effectiveExistingBytes == 0 {
                try handle.truncate(atOffset: 0)
            } else {
                try handle.seekToEnd()
            }

            fileHandle = handle
            downloadedBytes = effectiveExistingBytes

            if response.expectedContentLength > 0 {
                totalBytes = effectiveExistingBytes + Int(response.expectedContentLength)
            }

            progressHandler(downloadedBytes, totalBytes)
            completionHandler(.allow)
        } catch {
            continuation?.resume(throwing: error)
            continuation = nil
            completionHandler(.cancel)
        }
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        do {
            try fileHandle?.write(contentsOf: data)
            downloadedBytes += data.count
            progressHandler(downloadedBytes, totalBytes)
        } catch {
            dataTask.cancel()
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        try? fileHandle?.close()
        fileHandle = nil

        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }

        continuation = nil
    }
}

private extension URLSessionTask {
    var responseSupportsPartialContent: Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 206
    }
}
