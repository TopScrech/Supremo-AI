import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("LLM Chat") {
                LabeledContent("Inference families", value: InferenceKind.allCases.map(\.label).joined(separator: ", "))
                LabeledContent("Sampling", value: SamplingMethod.allCases.map(\.label).joined(separator: ", "))
            }
            
            Section("Reference") {
                if let swiftLlamaURL = URL(string: "https://github.com/ShenghaiWang/SwiftLlama") {
                    Link("SwiftLlama", destination: swiftLlamaURL)
                }
            }
        }
        .navigationTitle("About")
    }
}
