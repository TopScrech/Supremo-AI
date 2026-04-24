import SwiftLlama

actor Gemma4SwiftLlamaStore {
    private var modelPath = ""
    private var swiftLlama: SwiftLlama?
    
    func response(modelPath: String, configuration: Configuration, prompt: String) async throws -> String {
        let swiftLlama = try swiftLlama(modelPath: modelPath, configuration: configuration)
        return try await swiftLlama.start(rawPrompt: prompt)
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
