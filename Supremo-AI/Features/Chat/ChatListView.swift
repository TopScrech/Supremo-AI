import SwiftUI

struct ChatListView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @Binding var showSettings: Bool
    
    var body: some View {
        @Bindable var appModel = appModel
        
        List(selection: $appModel.selectedChatID) {
            ForEach(appModel.filteredChats) {
                ChatRowView($0)
                    .tag($0.id)
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
                Button("New Chat", systemImage: "plus", action: appModel.createChat)
            }
#endif
        }
    }
}
