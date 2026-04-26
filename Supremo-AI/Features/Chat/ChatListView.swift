import SwiftUI

struct ChatListView: View {
    @Environment(ChatAppModel.self) private var appModel
    @Binding var showSettings: Bool
    @State private var isRenamePresented = false
    @State private var renameTitle = ""
    @State private var chatToRename: ChatConfiguration?
    
    var body: some View {
        @Bindable var appModel = appModel
        
        List(selection: $appModel.selectedChatID) {
            ForEach(appModel.filteredChats) { chat in
                ChatRowView(chat)
                    .tag(chat.id)
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appModel.deleteChat(chat)
                        }
                        .labelStyle(.iconOnly)
                    }
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") {
                            prepareRename(for: chat)
                        }
                        
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            appModel.duplicateChat(chat)
                        }
                        
                        Divider()
                        
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            appModel.deleteChat(chat)
                        }
                    }
            }
            .onDelete(perform: appModel.deleteChats)
        }
        .alert("Rename Chat", isPresented: $isRenamePresented) {
            TextField("Name", text: $renameTitle)
            Button("Cancel", role: .cancel, action: resetRename)
            Button("Rename", action: renameChat)
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
    
    private func prepareRename(for chat: ChatConfiguration) {
        chatToRename = chat
        renameTitle = chat.title
        isRenamePresented = true
    }
    
    private func renameChat() {
        guard let chatToRename else { return }
        appModel.renameChat(chatToRename, title: renameTitle)
        resetRename()
    }
    
    private func resetRename() {
        chatToRename = nil
        renameTitle = ""
    }
}
