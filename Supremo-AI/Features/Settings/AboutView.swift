import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("LLM Chat") {
                LabeledContent("Inference families", value: InferenceKind.allCases.map(\.label).joined(separator: ", "))
                LabeledContent("Sampling", value: SamplingMethod.allCases.map(\.label).joined(separator: ", "))
                LabeledContent("Native backend", value: "llmfarm_core.swift")
                LabeledContent("Storage", value: URL.documentsDirectory.appending(path: "LLMChat").path())
            }
            
            Section("Reference") {
                if let llmFarmURL = URL(string: "https://github.com/guinmoon/LLMFarm") {
                    Link("LLMFarm", destination: llmFarmURL)
                }
                
                if let coreURL = URL(string: "https://github.com/guinmoon/llmfarm_core.swift") {
                    Link("llmfarm_core.swift", destination: coreURL)
                }
            }
        }
        .navigationTitle("About")
    }
}
