import SwiftUI

struct MissingInferenceBackend: View {
    let chat: ChatConfiguration
    let installAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Inference Unavailable", systemImage: "cpu")
        } description: {
            Text("\(chat.modelName) is installed and selected, but the native runner is unavailable for this model")
        } actions: {
            Button("Manage Models", systemImage: "shippingbox", action: installAction)
                .buttonStyle(.bordered)
        }
    }
}
