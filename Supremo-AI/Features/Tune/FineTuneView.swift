import SwiftUI

struct FineTuneView: View {
    @State private var datasetName = ""
    @State private var loraName = ""
    @State private var epochCount = 3
    
    var body: some View {
        Form {
            Section("LoRA Job") {
                TextField("Dataset", text: $datasetName)
                TextField("Adapter name", text: $loraName)
                Stepper("Epochs \(epochCount)", value: $epochCount, in: 1...20)
            }
            
            Section("Export") {
                Button("Export LoRA", systemImage: "square.and.arrow.up") {}
                    .disabled(loraName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Section("Engine") {
                Text("Fine-tuning controls are staged here to mirror LLMFarm. Training requires the native backend before jobs can run")
            }
        }
        .navigationTitle("Fine Tune")
    }
}
