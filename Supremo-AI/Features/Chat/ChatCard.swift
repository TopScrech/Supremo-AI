import ScrechKit

struct ChatCard: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let chat: ChatConfiguration
    
    init(_ chat: ChatConfiguration) {
        self.chat = chat
    }
    
    @State private var isRenamePresented = false
    @State private var renameTitle = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(chat.title)
                .headline()
            
            Text(chat.modelName)
                .subheadline()
                .secondary()
            
            Text(chat.updatedAt, format: .relative(presentation: .numeric))
                .caption()
                .foregroundStyle(.tertiary)
        }
        .alert("Rename Chat", isPresented: $isRenamePresented) {
            TextField("Name", text: $renameTitle)
            Button("Cancel", role: .cancel, action: resetRename)
            Button("Rename", action: renameChat)
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                appModel.deleteChat(chat)
            }
            .labelStyle(.iconOnly)
        }
        .contextMenu {
            Button("Rename", systemImage: "pencil", action: prepareRename)
            
            Button("Duplicate", systemImage: "plus.square.on.square") {
                appModel.duplicateChat(chat)
            }
            
            Divider()
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                appModel.deleteChat(chat)
            }
        }
    }
    
    private func prepareRename() {
        renameTitle = chat.title
        isRenamePresented = true
    }
    
    private func renameChat() {
        appModel.renameChat(chat, title: renameTitle)
        resetRename()
    }
    
    private func resetRename() {
        renameTitle = ""
    }
}
