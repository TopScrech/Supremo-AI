import SwiftUI

struct ChatUnavailableActionsView: View {
    let isModelReady: Bool
    let isInferenceBackendAvailable: Bool
    let initializationState: ModelInitializationState
    let selectModelAction: () -> Void
    let installModelAction: () -> Void
    let initializeAction: () -> Void
    
    var body: some View {
        HStack {
            if !isModelReady {
                Button("Select Model", systemImage: "shippingbox", action: selectModelAction)
#if !os(visionOS)
                    .buttonStyle(.glass)
#endif
                
                Button("Install Model", systemImage: "arrow.down.circle", action: installModelAction)
#if !os(visionOS)
                    .buttonStyle(.glassProminent)
#endif
            } else if !isInferenceBackendAvailable {
                Button("Install Model", systemImage: "arrow.down.circle", action: installModelAction)
#if !os(visionOS)
                    .buttonStyle(.glassProminent)
#endif
            } else {
                Button(initializationButtonTitle, systemImage: initializationButtonImage, action: initializeAction)
                    .disabled(initializationState == .initializing)
#if !os(visionOS)
                    .buttonStyle(.glassProminent)
#endif
            }
        }
    }
    
    private var initializationButtonTitle: String {
        switch initializationState {
        case .failed: "Try Again"
        case .initializing: "Initializing Model"
        case .idle, .ready: "Initialize Model"
        }
    }
    
    private var initializationButtonImage: String {
        initializationState == .failed ? "arrow.clockwise" : "power"
    }
}
