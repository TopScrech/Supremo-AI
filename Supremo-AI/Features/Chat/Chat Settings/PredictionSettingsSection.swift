import SwiftUI

struct PredictionSettingsSection: View {
    @Binding private var settings: PredictionSettings
    
    init(_ settings: Binding<PredictionSettings>) {
        _settings = settings
    }
    
    var body: some View {
        List {
            Stepper("Context \(settings.contextLength)", value: $settings.contextLength, in: 512...131072, step: 512)
            Stepper("Batch \(settings.batchSize)", value: $settings.batchSize, in: 32...4096, step: 32)
            Stepper("Threads \(settings.threadCount)", value: $settings.threadCount, in: 0...32)
            Stepper("Max output tokens \(settings.maxOutputTokens)", value: $settings.maxOutputTokens, in: 64...8192, step: 64)
            Toggle("Restore context state", isOn: $settings.restoreContextState)
            Toggle("Memory map model", isOn: $settings.mmap)
            Toggle("Lock model in memory", isOn: $settings.mlock)
            Toggle("Flash attention", isOn: $settings.flashAttention)
            Toggle("Add BOS token", isOn: $settings.addBosToken)
            Toggle("Add EOS token", isOn: $settings.addEosToken)
            Toggle("Parse special tokens", isOn: $settings.parseSpecialTokens)
        }
        .scrollIndicators(.never)
    }
}
