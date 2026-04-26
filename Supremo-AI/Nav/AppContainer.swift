import SwiftUI

struct AppContainer: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @State private var selectedSettingsScreen = SettingsScreen.models
    @State private var showSettings = false
    
    var body: some View {
        @Bindable var appModel = appModel
        
        NavigationSplitView {
            ChatListView(showSettings: $showSettings)
        } detail: {
            if let chat = appModel.selectedChat {
                ChatDetailView(
                    selectedSettingsScreen: $selectedSettingsScreen,
                    showAppSettings: $showSettings,
                    chat: chat
                )
            } else {
                EmptyChatView()
            }
        }
        .sheet(isPresented: $showSettings) {
            #if os(macOS)
            SettingsHomeView(selectedScreen: $selectedSettingsScreen)
            #else
            NavigationStack {
                SettingsHomeView(selectedScreen: $selectedSettingsScreen)
            }
            #endif
        }
        .task {
            if appModel.chats.isEmpty {
                appModel.load()
            }
        }
    }
}

#Preview {
    AppContainer()
        .environment(ChatAppModel())
}
