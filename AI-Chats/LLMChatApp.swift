import SwiftUI

@main
struct LLMChatApp: App {
    @State private var appModel = ChatAppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
    }
}
