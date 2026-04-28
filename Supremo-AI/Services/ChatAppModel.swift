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
    var downloadCapacityErrorMessages: [String: String] = [:]
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
    private var huggingFaceMetadataCache: [String: HuggingFaceModelMetadata] = [:]
    private var generationTask: Task<Void, Never>?
    private var typingTask: Task<Void, Never>?
    @ObservationIgnored private var downloadStateEntries: [String: DownloadStateEntry] = [:]
    
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
        var versionSelectionIDs = Set<String>()
        
        for model in downloadableModels {
            if model.supportsVersionSelection {
                guard versionSelectionIDs.insert(model.versionSelectionID).inserted else { continue }
            }

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
        downloadCapacityErrorMessages[model.fileName] ?? resolvedDownloadCapacityErrorMessage(for: model)
    }
    
    func downloadStateEntry(for fileName: String) -> DownloadStateEntry {
        if let entry = downloadStateEntries[fileName] {
            return entry
        }
        
        let entry = DownloadStateEntry(state: downloadStates[fileName])
        downloadStateEntries[fileName] = entry
        return entry
    }
    
    private func resolvedDownloadCapacityErrorMessage(for model: DownloadableModel) -> String? {
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
    
    func isMarkedNotForAllAudiences(_ model: DownloadableModel) async -> Bool {
        do {
            let metadata = try await huggingFaceModelMetadata(for: model)
            let tags = metadata.tags + (metadata.cardData?.tags ?? [])
            return tags.contains("not-for-all-audiences")
        } catch {
            logger.error("Unable to fetch metadata for \(model.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    func downloadableVersions(for model: DownloadableModel) async throws -> [DownloadableModel] {
        let metadata = try await huggingFaceModelMetadata(for: model)
        guard let modelID = huggingFaceModelID(from: model.url) else {
            throw URLError(.unsupportedURL)
        }

        return metadata.siblings
            .filter { isVersionSibling($0.rfilename, for: model.fileName) }
            .compactMap {
                downloadableModelVersion(from: $0, model: model, modelID: modelID)
            }
            .sorted {
                switch ($0.sizeBytes, $1.sizeBytes) {
                case let (lhs?, rhs?) where lhs != rhs:
                    return lhs < rhs
                    
                case (nil, _?):
                    return false
                    
                case (_?, nil):
                    return true
                    
                default:
                    return $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending
                }
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
    
    func assignModel(_ model: ModelFile, to chat: ChatConfiguration) async {
        guard model.isAvailableLocally else {
            logger.info("Finish downloading \(model.fileName, privacy: .public) before using it")
            return
        }

        let model = ggufTemplateEnrichedModel(await metadataEnrichedModel(model))
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
        refreshDownloadCapacityErrorMessages()
        persistStatus()
    }
    
    func deleteAllModels() {
        let deletedModelIDs = Set(modelFiles.map(\.id))
        
        for localURL in Set(modelFiles.compactMap(\.localURL)) where FileManager.default.fileExists(atPath: localURL.path()) {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        for model in modelFiles {
            setDownloadState(nil, for: model.fileName)
            setDownloadState(nil, for: completeFileName(forPartialDownload: model))
        }
        
        modelFiles.removeAll()
        
        for index in chats.indices {
            guard let modelFileID = chats[index].modelFileID, deletedModelIDs.contains(modelFileID) else { continue }
            
            chats[index].modelFileID = nil
            chats[index].modelName = "No model selected"
            chats[index].updatedAt = Date()
        }
        
        logger.info("Deleted all local models")
        refreshDownloadCapacityErrorMessages()
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
        if let generationTask {
            generationTask.cancel()
            await generationTask.value
            self.generationTask = nil
        }
        
        let task = Task {
            await runPrompt(prompt, useRAG: useRAG)
        }
        
        generationTask = task
        await task.value
        generationTask = nil
    }
    
    func stopGenerating() {
        generationTask?.cancel()
        isGenerating = false
        startTypingTaskIfNeeded()
        persistStatus()
    }
    
    private func runPrompt(_ prompt: String, useRAG: Bool) async {
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
        defer {
            isGenerating = false
            startTypingTaskIfNeeded()
            persistStatus()
        }
        
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
                try Task.checkCancellation()
                updateMessageTarget(assistantMessage.id, in: chatSnapshot.id, text: partialResponse)
            }
            
            updateChatTimestamp(chatSnapshot.id)
            logger.info("Generated streaming response")
        } catch is CancellationError {
            updateChatTimestamp(chatSnapshot.id)
            logger.info("Stopped streaming response")
        } catch {
            updateLatestAssistantMessage(in: chatSnapshot.id, fallbackText: error.localizedDescription)
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
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
            let model = ModelFile(displayName: url.deletingPathExtension().lastPathComponent, fileName: url.lastPathComponent, localURL: destination, remoteURL: nil, quantization: ModelQuantization.value(from: url.lastPathComponent, fallback: "Local"), family: .llama)
            modelFiles.append(model)
            if let selectedChat, selectedChat.modelFileID == nil {
                Task {
                    await assignModel(model, to: selectedChat)
                }
            }
            logger.info("Imported \(model.fileName, privacy: .public)")
            persistStatus()
        } catch {
            logger.error("\(error.localizedDescription, privacy: .public)")
        }
    }
    
    func registerDownloadedModel(_ downloadableModel: DownloadableModel, localURL: URL) async {
        let metadata = try? await huggingFaceModelMetadata(for: downloadableModel)
        modelFiles.removeAll { $0.fileName == downloadableModel.fileName || $0.fileName == "\(downloadableModel.fileName).download" }
        let model = ModelFile(
            displayName: downloadableModel.familyName,
            fileName: downloadableModel.fileName,
            localURL: localURL,
            remoteURL: downloadableModel.url,
            quantization: downloadableModel.quantization,
            family: metadata?.inferenceKind ?? downloadableModel.inference,
            promptTemplate: metadata?.cardData?.promptTemplate
        )
        modelFiles.append(model)
        if let selectedChat, selectedChat.modelFileID == nil {
            await assignModel(model, to: selectedChat)
        }
        logger.info("Added \(downloadableModel.fileName, privacy: .public)")
        refreshDownloadCapacityErrorMessages()
        persistStatus()
    }
    
    func download(_ model: DownloadableModel) async {
#if os(iOS)
        if #available(iOS 26, *) {
            startContinuedProcessingDownload(model)
            return
        }
#endif
        
        _ = await performDownload(model, progress: nil)
    }
    
    private func startContinuedProcessingDownload(_ model: DownloadableModel) {
        BackgroundModelDownloadScheduler.shared.schedule(
            title: "Downloading Model",
            subtitle: model.familyName
        ) { [weak self] progress in
            await self?.performDownload(model, progress: progress) ?? false
        }
    }
    
    private func performDownload(_ model: DownloadableModel, progress: Progress?) async -> Bool {
        guard downloadStates[model.fileName]?.isDownloading != true else { return true }
        
        await refreshDownloadSize(for: model)
        let currentModel = downloadableModels.first { $0.fileName == model.fileName } ?? model
        
        let destination = store.modelsURL.appending(path: currentModel.fileName)
        let partialDestination = store.modelsURL.appending(path: "\(currentModel.fileName).download")
        
        do {
            logger.info("Downloading \(currentModel.fileName, privacy: .public)")
            try store.ensureDirectories()
            let existingBytes = fileSize(for: partialDestination)
            updateDownloadCapacityErrorMessage(for: currentModel)
            if let errorMessage = downloadCapacityErrorMessages[currentModel.fileName] {
                setDownloadState(
                    DownloadState(downloadedBytes: existingBytes, totalBytes: currentModel.sizeBytes, isDownloading: false, errorMessage: errorMessage),
                    for: currentModel.fileName
                )
                return false
            }
            
            setDownloadState(
                DownloadState(downloadedBytes: existingBytes, totalBytes: currentModel.sizeBytes, isDownloading: true),
                for: currentModel.fileName
            )
            
            createPartialDownloadFileIfNeeded(at: partialDestination)
            refreshModelFilesFromDisk()
            try await downloadFile(from: currentModel.url, to: partialDestination, modelFileName: currentModel.fileName, progress: progress)
            
            if FileManager.default.fileExists(atPath: destination.path()) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: partialDestination, to: destination)
            updateDownloadState(for: currentModel.fileName) {
                $0.isDownloading = false
            }
            await registerDownloadedModel(currentModel, localURL: destination)
            return true
        } catch {
            refreshModelFilesFromDisk()
            setDownloadState(
                DownloadState(downloadedBytes: fileSize(for: partialDestination), totalBytes: currentModel.sizeBytes, isDownloading: false, errorMessage: error.localizedDescription),
                for: currentModel.fileName
            )
            logger.error("\(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    func continueDownload(_ model: ModelFile) async {
        guard let downloadableModel = downloadableModel(forPartialDownload: model) else { return }
        await download(downloadableModel)
    }
    
    private func downloadFile(from url: URL, to destination: URL, modelFileName: String, progress: Progress?) async throws {
        let existingBytes = fileSize(for: destination)
        var request = URLRequest(url: url)
        if existingBytes > 0 {
            request.setValue("bytes=\(existingBytes)-", forHTTPHeaderField: "Range")
        }
        
        let delegate = ModelDataDownloadDelegate(destination: destination, existingBytes: existingBytes) { [weak self] downloadedBytes, totalBytes in
            Task { @MainActor [weak self] in
                if let totalBytes {
                    progress?.totalUnitCount = Int64(totalBytes)
                }
                progress?.completedUnitCount = Int64(downloadedBytes)
                self?.updateDownloadProgress(modelFileName: modelFileName, downloadedBytes: downloadedBytes, totalBytes: totalBytes)
            }
        }
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        defer {
            session.invalidateAndCancel()
        }
        
        try await withTaskCancellationHandler {
            try await delegate.download(request, using: session)
        } onCancel: {
            session.invalidateAndCancel()
        }
    }
    
    private func updateDownloadProgress(modelFileName: String, downloadedBytes: Int, totalBytes: Int?) {
        updateDownloadState(for: modelFileName) {
            $0.downloadedBytes = downloadedBytes
            $0.totalBytes = totalBytes
        }
    }
    
    private func setDownloadState(_ state: DownloadState?, for fileName: String) {
        downloadStates[fileName] = state
        downloadStateEntry(for: fileName).state = state
    }
    
    private func updateDownloadState(for fileName: String, update: (inout DownloadState) -> Void) {
        guard var state = downloadStates[fileName] else { return }
        update(&state)
        setDownloadState(state, for: fileName)
    }
    
    private func downloadableModel(forPartialDownload model: ModelFile) -> DownloadableModel? {
        let fileName = completeFileName(forPartialDownload: model)
        
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
    
    private func completeFileName(forPartialDownload model: ModelFile) -> String {
        let downloadFileSuffix = ".download"
        return model.fileName.hasSuffix(downloadFileSuffix) ? String(model.fileName.dropLast(downloadFileSuffix.count)) : model.fileName
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
            updateDownloadCapacityErrorMessage(for: downloadableModels[index])
        } catch {
            logger.error("Unable to fetch size for \(model.fileName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private func updateDownloadCapacityErrorMessage(for model: DownloadableModel) {
        downloadCapacityErrorMessages[model.fileName] = resolvedDownloadCapacityErrorMessage(for: model)
    }
    
    private func refreshDownloadCapacityErrorMessages() {
        for model in downloadableModels {
            updateDownloadCapacityErrorMessage(for: model)
        }
    }
    
    private func remainingDownloadBytes(for model: DownloadableModel) -> Int64? {
        let currentModel = downloadableModels.first { $0.fileName == model.fileName } ?? model
        guard let sizeBytes = currentModel.sizeBytes else { return nil }
        let partialDestination = store.modelsURL.appending(path: "\(model.fileName).download")
        let existingBytes = fileSize(for: partialDestination)
        return Int64(max(sizeBytes - existingBytes, 0))
    }
    
    private func huggingFaceModelID(from url: URL) -> String? {
        guard url.host == "huggingface.co" else { return nil }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3 else { return nil }
        
        return "\(pathComponents[1])/\(pathComponents[2])"
    }
    
    private func huggingFaceModelMetadata(for model: DownloadableModel) async throws -> HuggingFaceModelMetadata {
        try await huggingFaceModelMetadata(for: model.url)
    }
    
    private func huggingFaceModelMetadata(for url: URL) async throws -> HuggingFaceModelMetadata {
        guard let modelID = huggingFaceModelID(from: url) else {
            throw URLError(.unsupportedURL)
        }
        
        return try await huggingFaceModelMetadata(for: modelID)
    }
    
    private func huggingFaceModelMetadata(for modelID: String) async throws -> HuggingFaceModelMetadata {
        if let metadata = huggingFaceMetadataCache[modelID] {
            return metadata
        }
        
        guard let url = URL(string: "https://huggingface.co/api/models/\(modelID)?blobs=true") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let metadata = try JSONDecoder().decode(HuggingFaceModelMetadata.self, from: data)
        huggingFaceMetadataCache[modelID] = metadata
        return metadata
    }

    private func downloadableModelVersion(from sibling: HuggingFaceModelSibling, model: DownloadableModel, modelID: String) -> DownloadableModel? {
        guard let repositoryURL = URL(string: "https://huggingface.co/\(modelID)/resolve/main") else { return nil }
        
        let url = repositoryURL.appending(path: sibling.rfilename).appending(queryItems: [
            URLQueryItem(name: "download", value: "true")
        ])

        return DownloadableModel(
            familyName: model.familyName,
            fileName: sibling.rfilename,
            url: url,
            quantization: ModelQuantization.value(from: sibling.rfilename),
            sizeBytes: sibling.resolvedSizeBytes,
            inference: model.inference
        )
    }

    private func isVersionSibling(_ fileName: String, for modelFileName: String) -> Bool {
        guard fileName.hasSuffix(".gguf") else { return false }
        let versionPrefix = ModelQuantization.filePrefix(from: modelFileName)
        guard !versionPrefix.isEmpty else { return true }
        return normalizedVersionFileName(fileName).hasPrefix(normalizedVersionFileName(versionPrefix))
    }

    private func normalizedVersionFileName(_ fileName: String) -> String {
        fileName.lowercased()
            .replacing(" ", with: "")
            .replacing("-", with: "")
            .replacing("_", with: "")
            .replacing(".", with: "")
    }

    private func metadataEnrichedModel(_ model: ModelFile) async -> ModelFile {
        guard let remoteURL = model.remoteURL,
              let metadata = try? await huggingFaceModelMetadata(for: remoteURL) else {
            return model
        }
        
        var enrichedModel = model
        enrichedModel.family = metadata.inferenceKind ?? model.family
        enrichedModel.promptTemplate = metadata.cardData?.promptTemplate ?? model.promptTemplate
        
        guard let index = modelFiles.firstIndex(where: { $0.id == model.id }) else {
            return enrichedModel
        }
        
        modelFiles[index] = enrichedModel
        persistStatus()
        return enrichedModel
    }

    private func ggufTemplateEnrichedModel(_ model: ModelFile) -> ModelFile {
        guard let localURL = model.localURL,
              let promptTemplate = GGUFPromptTemplateReader.promptTemplate(from: localURL) else {
            return model
        }

        var enrichedModel = model
        enrichedModel.ggufPromptTemplate = promptTemplate

        guard let index = modelFiles.firstIndex(where: { $0.id == model.id }) else {
            return enrichedModel
        }

        modelFiles[index] = enrichedModel
        persistStatus()
        return enrichedModel
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
        if lowercasedFileName.localizedStandardContains("mixtral") { return .mixtral }
        if lowercasedFileName.localizedStandardContains("mistral") || lowercasedFileName.localizedStandardContains("ministral") { return .mistral }
        if lowercasedFileName.localizedStandardContains("nemotron") { return .nemotron }
        if lowercasedFileName.localizedStandardContains("lfm2") { return .lfm2 }
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

private struct HuggingFaceModelMetadata: Decodable {
    var tags: [String]
    var gguf: HuggingFaceGGUFMetadata?
    var cardData: HuggingFaceModelCardData?
    var siblings: [HuggingFaceModelSibling]
    
    nonisolated var inferenceKind: InferenceKind? {
        let values = [
            gguf?.architecture,
            cardData?.modelType,
            cardData?.modelName,
            cardData?.baseModel
        ] + tags
        
        return values.compactMap { $0 }.compactMap(Self.inferenceKind).first
    }
    
    private enum CodingKeys: String, CodingKey {
        case tags, gguf, cardData, siblings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        gguf = try container.decodeIfPresent(HuggingFaceGGUFMetadata.self, forKey: .gguf)
        cardData = try container.decodeIfPresent(HuggingFaceModelCardData.self, forKey: .cardData)
        siblings = try container.decodeIfPresent([HuggingFaceModelSibling].self, forKey: .siblings) ?? []
    }
    
    nonisolated private static func inferenceKind(from value: String) -> InferenceKind? {
        let lowercasedValue = value.lowercased()
        if lowercasedValue.localizedStandardContains("gemma") { return .gemma }
        if lowercasedValue.localizedStandardContains("deepseek") { return .deepseek }
        if lowercasedValue.localizedStandardContains("qwen") { return .qwen }
        if lowercasedValue.localizedStandardContains("baichuan") { return .baichuan }
        if lowercasedValue.localizedStandardContains("phi") { return .phi }
        if lowercasedValue.localizedStandardContains("mixtral") { return .mixtral }
        if lowercasedValue.localizedStandardContains("mistral") || lowercasedValue.localizedStandardContains("ministral") { return .mistral }
        if lowercasedValue.localizedStandardContains("nemotron") { return .nemotron }
        if lowercasedValue.localizedStandardContains("lfm2") { return .lfm2 }
        if lowercasedValue.localizedStandardContains("llava") { return .llava }
        if lowercasedValue.localizedStandardContains("moondream") { return .moondream }
        if lowercasedValue.localizedStandardContains("starcoder") { return .starcoder }
        if lowercasedValue.localizedStandardContains("falcon") { return .falcon }
        if lowercasedValue.localizedStandardContains("gpt2") || lowercasedValue.localizedStandardContains("gpt-2") { return .gpt2 }
        if lowercasedValue.localizedStandardContains("llama") { return .llama }
        return nil
    }
}

private struct HuggingFaceModelSibling: Decodable {
    var rfilename: String
    var size: Int?
    var lfs: HuggingFaceModelSiblingLFS?

    var resolvedSizeBytes: Int? {
        size ?? lfs?.size
    }
}

private struct HuggingFaceModelSiblingLFS: Decodable {
    var size: Int?
}

private struct HuggingFaceGGUFMetadata: Decodable {
    var architecture: String?
    
    private enum CodingKeys: String, CodingKey {
        case architecture
    }
}

private struct HuggingFaceModelCardData: Decodable {
    var tags: [String]
    var baseModel: String?
    var modelName: String?
    var modelType: String?
    var promptTemplate: String?
    
    private enum CodingKeys: String, CodingKey {
        case tags
        case baseModel = "base_model"
        case modelName = "model_name"
        case modelType = "model_type"
        case promptTemplate = "prompt_template"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        baseModel = try container.decodeIfPresent(String.self, forKey: .baseModel)
        modelName = try container.decodeIfPresent(String.self, forKey: .modelName)
        modelType = try container.decodeIfPresent(String.self, forKey: .modelType)
        promptTemplate = try container.decodeIfPresent(String.self, forKey: .promptTemplate)
    }
}

private final class ModelDataDownloadDelegate: NSObject, URLSessionDataDelegate {
    private static let progressUpdateInterval: TimeInterval = 1
    private static let progressUpdateByteInterval = 16 * 1024 * 1024
    
    private let destination: URL
    private let existingBytes: Int
    private let progressHandler: @Sendable (Int, Int?) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private var fileHandle: FileHandle?
    private var downloadedBytes = 0
    private var totalBytes: Int?
    private var lastProgressUpdate = Date.distantPast
    private var lastProgressBytes = 0
    
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
            
            reportProgress(force: true)
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
            reportProgress()
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
        reportProgress(force: true)
        
        if let error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
        
        continuation = nil
    }
    
    private func reportProgress(force: Bool = false) {
        let now = Date()
        let hasEnoughBytes = downloadedBytes - lastProgressBytes >= Self.progressUpdateByteInterval
        let hasEnoughTime = now.timeIntervalSince(lastProgressUpdate) >= Self.progressUpdateInterval
        
        guard force || hasEnoughBytes || hasEnoughTime else { return }
        
        lastProgressUpdate = now
        lastProgressBytes = downloadedBytes
        progressHandler(downloadedBytes, totalBytes)
    }
}

private extension URLSessionTask {
    var responseSupportsPartialContent: Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 206
    }
}
