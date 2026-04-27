import Foundation
import SwiftLlama
import OSLog

protocol LocalInferenceEngine {
    var isAvailable: Bool { get }
    func prepare(chat: ChatConfiguration) async throws
    func eject(chat: ChatConfiguration) async
    func response(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> String
    func responseStream(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> AsyncThrowingStream<String, Error>
}

enum InferenceEngineError: LocalizedError {
    case backendUnavailable

    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            "The native inference backend could not load the selected model"
        }
    }
}

struct SwiftLlamaInferenceEngine: LocalInferenceEngine {
    let isAvailable = true
    private static let swiftLlamaStore = SwiftLlamaModelStore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AI-Chats", category: "LocalInferenceEngine")

    func prepare(chat: ChatConfiguration) async throws {
        guard let modelURL = chat.modelFileURL else {
            throw InferenceEngineError.backendUnavailable
        }

        try await Self.swiftLlamaStore.prepare(modelPath: modelURL.path(), configuration: swiftLlamaConfiguration(for: chat))
    }

    func eject(chat: ChatConfiguration) async {
        guard let modelURL = chat.modelFileURL else { return }

        await Self.swiftLlamaStore.eject(modelPath: modelURL.path())
    }

    func response(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> String {
        guard let modelURL = chat.modelFileURL else {
            throw InferenceEngineError.backendUnavailable
        }

        let input = promptWithRAG(prompt: prompt, context: context)
        return try await swiftLlamaResponse(for: input, chat: chat, modelURL: modelURL)
    }

    func responseStream(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> AsyncThrowingStream<String, Error> {
        guard let modelURL = chat.modelFileURL else {
            throw InferenceEngineError.backendUnavailable
        }

        let input = promptWithRAG(prompt: prompt, context: context)
        return try await swiftLlamaResponseStream(for: input, chat: chat, modelURL: modelURL)
    }

    private func swiftLlamaResponse(for prompt: String, chat: ChatConfiguration, modelURL: URL) async throws -> String {
        let configuration = swiftLlamaConfiguration(for: chat)
        let formattedPrompt = formattedSwiftLlamaPrompt(prompt, chat: chat)
        logger.info("Starting SwiftLlama response. promptCharacters=\(formattedPrompt.count, privacy: .public) batchSize=\(configuration.batchSize, privacy: .public) context=\(configuration.nCTX, privacy: .public) maxTokens=\(configuration.maxTokenCount, privacy: .public)")
        let rawOutput = try await Self.swiftLlamaStore.response(
            modelPath: modelURL.path(),
            configuration: configuration,
            prompt: formattedPrompt
        )
        logger.info("Finished SwiftLlama response. outputCharacters=\(rawOutput.count, privacy: .public)")
        return cleanedSwiftLlamaOutput(rawOutput)
    }

    private func swiftLlamaResponseStream(for prompt: String, chat: ChatConfiguration, modelURL: URL) async throws -> AsyncThrowingStream<String, Error> {
        let configuration = swiftLlamaConfiguration(for: chat)
        let formattedPrompt = formattedSwiftLlamaPrompt(prompt, chat: chat)
        logger.info("Starting SwiftLlama response stream. promptCharacters=\(formattedPrompt.count, privacy: .public) batchSize=\(configuration.batchSize, privacy: .public) context=\(configuration.nCTX, privacy: .public) maxTokens=\(configuration.maxTokenCount, privacy: .public)")
        let rawStream = try await Self.swiftLlamaStore.responseStream(
            modelPath: modelURL.path(),
            configuration: configuration,
            prompt: formattedPrompt
        )

        return AsyncThrowingStream { continuation in
            Task {
                var rawOutput = ""
                do {
                    for try await delta in rawStream {
                        rawOutput += delta
                        continuation.yield(cleanedSwiftLlamaOutput(rawOutput))
                    }
                    logger.info("Finished SwiftLlama response stream. outputCharacters=\(rawOutput.count, privacy: .public)")
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func swiftLlamaConfiguration(for chat: ChatConfiguration) -> Configuration {
        Configuration(
            seed: 1234,
            topK: chat.settings.sampling.topK,
            topP: Float(chat.settings.sampling.topP),
            nCTX: chat.settings.prediction.contextLength,
            temperature: Float(chat.settings.sampling.temperature),
            batchSize: chat.settings.prediction.batchSize,
            useMetal: false,
            maxTokenCount: chat.settings.prediction.maxTokens,
            stopTokens: swiftLlamaStopTokens(for: chat)
        )
    }

    private func formattedSwiftLlamaPrompt(_ prompt: String, chat: ChatConfiguration) -> String {
        var formattedPrompt = chat.settings.prompt.promptFormat
            .replacingOccurrences(of: "{{prompt}}", with: prompt)
            .replacingOccurrences(of: "{prompt}", with: prompt)
            .replacingOccurrences(of: "\\n", with: "\n")

        let systemPrompt = chat.settings.prompt.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !systemPrompt.isEmpty && formattedPrompt.hasPrefix("<|turn>user") {
            formattedPrompt = "<|turn>system\n\(systemPrompt)<turn|>\n" + formattedPrompt
        }

        return formattedPrompt
    }

    private func swiftLlamaStopTokens(for chat: ChatConfiguration) -> [String] {
        let customStopTokens = chat.settings.prompt.reversePrompt
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var stopTokens: [String] = []
        for token in customStopTokens + ["<turn|>", "<|turn>user", "<|turn>system", "<｜end▁of▁sentence｜>", "<｜User｜>"] where !stopTokens.contains(token) {
            stopTokens.append(token)
        }
        return stopTokens
    }

    private func cleanedSwiftLlamaOutput(_ output: String) -> String {
        output
            .replacing("<turn|>", with: "")
            .replacing("<｜end▁of▁sentence｜>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func promptWithRAG(prompt: String, context: [RAGDocument]) -> String {
        guard !context.isEmpty else { return prompt }

        let contextText = context
            .map { "\($0.title)\n\($0.text)" }
            .joined(separator: "\n\n")

        return """
        Use the following context when it is relevant.

        \(contextText)

        User prompt:
        \(prompt)
        """
    }
}
