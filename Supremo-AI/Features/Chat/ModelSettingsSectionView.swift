import SwiftUI

struct ModelSettingsSectionView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        Section("Model") {
            Picker("Inference", selection: $chat.settings.inference) {
                ForEach(InferenceKind.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            
            Picker("Local Model", selection: $chat.modelFileID) {
                Text("None")
                    .tag(UUID?.none)
                
                ForEach(appModel.modelFiles) {
                    Text($0.displayName)
                        .tag(UUID?.some($0.id))
                }
            }
            .onChange(of: chat.modelFileID) { _, newValue in
                if let model = appModel.modelFiles.first(where: { $0.id == newValue }) {
                    chat.modelName = model.displayName
                    chat.settings.inference = model.family
                }
            }
            
            Toggle("Metal", isOn: $chat.settings.prediction.useMetal)
            Toggle("CLIP Metal", isOn: $chat.settings.prediction.useClipMetal)
        }
    }
}
