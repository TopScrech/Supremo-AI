import SwiftUI

struct MissingInferenceBackend: View {
    private let chat: ChatConfiguration
    private let installAction: () -> Void
    
    init(_ chat: ChatConfiguration, installAction: @escaping () -> Void) {
        self.chat = chat
        self.installAction = installAction
    }
    
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
