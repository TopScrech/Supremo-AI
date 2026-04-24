import SwiftUI

struct ChatListView: View {
    @Environment(ChatAppModel.self) private var appModel
    @Binding var showSettings: Bool

    var body: some View {
        @Bindable var appModel = appModel

        List(selection: $appModel.selectedChatID) {
            ForEach(appModel.filteredChats) { chat in
                ChatRowView(chat: chat)
                    .tag(chat.id)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appModel.deleteChat(chat)
                        }
                    }
                    .contextMenu {
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            appModel.duplicateChat(chat)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appModel.deleteChat(chat)
                        }
                    }
            }
            .onDelete(perform: appModel.deleteChats)
        }
        .searchable(text: $appModel.searchText, prompt: "Search chats")
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItemGroup {
                Button("Settings", systemImage: "gear") {
                    showSettings = true
                }
                Button("New Chat", systemImage: "plus") {
                    appModel.createChat()
                }
            }
        }
    }
}
