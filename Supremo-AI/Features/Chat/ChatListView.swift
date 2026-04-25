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
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem {
                Button("Settings", systemImage: "gear") {
                    showSettings = true
                }
            }
#if !os(macOS)
            ToolbarItem(placement: .bottomBar) {
                TextField("  Search chats", text: $appModel.searchText)
            }
            
            ToolbarSpacer(.fixed, placement: .bottomBar)
            
            ToolbarItem(placement: .bottomBar) {
                Button("New Chat", systemImage: "plus") {
                    appModel.createChat()
                }
            }
#endif
        }
    }
}
