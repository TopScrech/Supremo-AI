import SwiftUI

struct ModelSettingsSectionView: View {
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        Section("Model") {
            Picker("Inference", selection: $chat.settings.inference) {
                ForEach(InferenceKind.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }

            Toggle("Metal", isOn: $chat.settings.prediction.useMetal)
            Toggle("CLIP Metal", isOn: $chat.settings.prediction.useClipMetal)
        }
    }
}
