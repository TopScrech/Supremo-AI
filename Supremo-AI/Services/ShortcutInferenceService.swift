import Foundation

struct ShortcutInferenceService {
    private let store = JSONFileStore()
    private let inferenceEngine: LocalInferenceEngine = SwiftLlamaInferenceEngine()
    private let modelLibrary = ShortcutModelLibrary()
    private let ragIndexer = RAGIndexer()

    func response(prompt: String, modelID: UUID?) async throws -> String {
        try await response(prompt: prompt, modelID: modelID, rejectsEmptyResponse: false)
    }

    private func response(prompt: String, modelID: UUID?, rejectsEmptyResponse: Bool) async throws -> String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw ShortcutInferenceError.emptyPrompt
        }

        try store.ensureDirectories()
        var chats = try store.load([ChatConfiguration].self, from: "chats.json")
        let modelFiles = try modelLibrary.localModels()

        guard let chatIndex = chats.indices.first else {
            throw ShortcutInferenceError.missingChat
        }

        guard let model = modelLibrary.selectedModel(for: chats[chatIndex], preferredModelID: modelID, in: modelFiles),
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
        if rejectsEmptyResponse && response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ShortcutInferenceError.emptyResponse
        }

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

    func summary(text: String, modelID: UUID?) async throws -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw ShortcutInferenceError.emptyPrompt
        }

        let primaryPrompt = """
        Write a concise summary of the text below.

        Text:
        \(trimmedText)

        Summary:
        """

        do {
            return try await response(prompt: primaryPrompt, modelID: modelID, rejectsEmptyResponse: true)
        } catch ShortcutInferenceError.emptyResponse {
            let retryPrompt = """
            Summarize this text in one short paragraph:

            \(trimmedText)
            """

            return try await response(prompt: retryPrompt, modelID: modelID, rejectsEmptyResponse: true)
        }
    }
}
