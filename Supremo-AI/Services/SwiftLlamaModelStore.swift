import SwiftLlama

actor SwiftLlamaModelStore {
    private var modelPath = ""
    private var swiftLlama: SwiftLlama?
    
    func prepare(modelPath: String, configuration: Configuration) throws {
        _ = try swiftLlama(modelPath: modelPath, configuration: configuration)
    }
    
    func response(modelPath: String, configuration: Configuration, prompt: String) async throws -> String {
        let swiftLlama = try swiftLlama(modelPath: modelPath, configuration: configuration)
        return try await swiftLlama.start(rawPrompt: prompt)
    }
    
    func responseStream(modelPath: String, configuration: Configuration, prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        let swiftLlama = try swiftLlama(modelPath: modelPath, configuration: configuration)
        return try await swiftLlama.start(for: Prompt(type: .raw, userMessage: prompt))
    }
    
    func eject(modelPath: String) {
        guard self.modelPath == modelPath else { return }
        
        swiftLlama = nil
        self.modelPath = ""
    }
    
    private func swiftLlama(modelPath: String, configuration: Configuration) throws -> SwiftLlama {
        if self.modelPath == modelPath, let swiftLlama {
            return swiftLlama
        }
        
        let swiftLlama = try SwiftLlama(modelPath: modelPath, modelConfiguration: configuration)
        self.modelPath = modelPath
        self.swiftLlama = swiftLlama
        return swiftLlama
    }
}
