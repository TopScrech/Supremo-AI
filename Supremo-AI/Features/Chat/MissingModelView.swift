import SwiftUI

struct MissingModelView: View {
    let chat: ChatConfiguration
    let installAction: () -> Void
    let editAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Model Selected", systemImage: "shippingbox")
        } description: {
            Text("Install a GGUF model or select an imported model before chatting")
        } actions: {
            HStack {
                Button("Select Model", systemImage: "slider.horizontal.3", action: editAction)
                    .buttonStyle(.bordered)
                
                Button("Install Model", systemImage: "arrow.down.circle", action: installAction)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
