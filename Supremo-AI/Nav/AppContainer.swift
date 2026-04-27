import SwiftUI

struct AppContainer: View {
    @Environment(ChatAppModel.self) private var appModel
    @AppStorage("disableStatusBar") private var disableStatusBar = false
    
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
        .appStatusBarHidden(disableStatusBar)
    }
}

private extension View {
    @ViewBuilder
    func appStatusBarHidden(_ hidden: Bool) -> some View {
#if os(iOS)
        statusBarHidden(hidden)
#else
        self
#endif
    }
}

#Preview {
    AppContainer()
        .environment(ChatAppModel())
}
