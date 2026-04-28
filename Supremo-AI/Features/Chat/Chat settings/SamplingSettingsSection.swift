import SwiftUI

struct SamplingSettingsSection: View {
    @Binding var settings: SamplingSettings
    
    var body: some View {
        Section("Sampling") {
            Picker("Method", selection: $settings.method) {
                ForEach(SamplingMethod.allCases) {
                    Text($0.label).tag($0)
                }
            }
            
            Slider(value: $settings.temperature, in: 0...2) {
                Text("Temperature")
            }
            LabeledContent("Temperature", value: settings.temperature, format: .number.precision(.fractionLength(2)))
            
            Stepper("Top K \(settings.topK)", value: $settings.topK, in: 0...200)
            
            Slider(value: $settings.topP, in: 0...1) {
                Text("Top P")
            }
            
            LabeledContent("Top P", value: settings.topP, format: .number.precision(.fractionLength(2)))
            
            Slider(value: $settings.tailFreeSampling, in: 0...1) {
                Text("Tail free sampling")
            }
            
            Slider(value: $settings.typicalP, in: 0...1) {
                Text("Typical P")
            }
            
            Stepper("Repeat last \(settings.repeatLastN)", value: $settings.repeatLastN, in: 0...4096)
            
            Slider(value: $settings.repeatPenalty, in: 0...2) {
                Text("Repeat penalty")
            }
            
            Slider(value: $settings.mirostatTau, in: 0...10) {
                Text("Mirostat tau")
            }
            
            Slider(value: $settings.mirostatEta, in: 0...1) {
                Text("Mirostat eta")
            }
            
            TextField("Grammar", text: $settings.grammar)
        }
    }
}
