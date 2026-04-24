import SwiftUI

struct ContentView: View {
    @Environment(ChatAppModel.self) private var appModel

    var body: some View {
        AppShellView()
            .task {
                if appModel.chats.isEmpty {
                    appModel.load()
                }
            }
    }
}

#Preview {
    ContentView()
        .environment(ChatAppModel())
}
