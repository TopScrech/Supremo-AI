import SwiftUI

struct ModelInitializationView: View {
    let chat: ChatConfiguration
    let state: ModelInitializationState
    let message: String?
    let initializeAction: () -> Void
    let ejectAction: () -> Void
    let editAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label(state.title, systemImage: state.systemImage)
        } description: {
            Text(description)
        } actions: {
            HStack {
                Button("Chat Settings", systemImage: "slider.horizontal.3", action: editAction)
                    .buttonStyle(.glass)
                    .disabled(state == .initializing)
                
                Button(buttonTitle, systemImage: buttonImage, action: initializeAction)
                    .buttonStyle(.glassProminent)
                    .disabled(state == .initializing)
            }
        }
    }
    
    private var description: String {
        switch state {
        case .initializing: "Loading \(chat.modelName) before the first message"
        case .failed: message ?? "The selected model could not be loaded"
        case .ready: "\(chat.modelName) is ready for chat"
        case .idle: "Load \(chat.modelName) before sending messages"
        }
    }
    
    private var buttonTitle: String {
        state == .failed ? "Try Again" : "Initialize Model"
    }
    
    private var buttonImage: String {
        state == .failed ? "arrow.clockwise" : "power"
    }
}
