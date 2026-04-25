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
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        } actions: {
            VStack {
                Button(buttonTitle, systemImage: buttonImage, action: initializeAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(state == .initializing)
                
                if state == .ready {
                    Button("Eject Model", systemImage: "eject", action: ejectAction)
                        .buttonStyle(.bordered)
                }
                
                Button("Chat Settings", systemImage: "slider.horizontal.3", action: editAction)
                    .buttonStyle(.bordered)
                    .disabled(state == .initializing)
            }
        }
    }
    
    private var title: String {
        switch state {
        case .initializing:
            "Initializing Model"
        case .failed:
            "Model Initialization Failed"
        case .ready:
            "Model Ready"
        case .idle:
            "Initialize Model"
        }
    }
    
    private var description: String {
        switch state {
        case .initializing:
            "Loading \(chat.modelName) before the first message"
        case .failed:
            message ?? "The selected model could not be loaded"
        case .ready:
            "\(chat.modelName) is ready for chat"
        case .idle:
            "Load \(chat.modelName) before sending messages"
        }
    }
    
    private var systemImage: String {
        switch state {
        case .initializing:
            "cpu"
        case .failed:
            "exclamationmark.triangle"
        case .ready:
            "checkmark.circle"
        case .idle:
            "power"
        }
    }
    
    private var buttonTitle: String {
        state == .failed ? "Try Again" : "Initialize Model"
    }
    
    private var buttonImage: String {
        state == .failed ? "arrow.clockwise" : "power"
    }
}
