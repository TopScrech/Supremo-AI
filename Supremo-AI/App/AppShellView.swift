import SwiftUI

struct AppShellView: View {
    @Environment(ChatAppModel.self) private var appModel
    @State private var selectedSettingsScreen = SettingsScreen.models
    @State private var showSettings = false

    var body: some View {
        @Bindable var appModel = appModel

        NavigationSplitView {
            ChatListView(showSettings: $showSettings)
        } detail: {
            if let chat = appModel.selectedChat {
                ChatDetailView(chat: chat)
            } else {
                EmptyChatView()
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsHomeView(selectedScreen: $selectedSettingsScreen)
            }
        }
    }
}
