import ScrechKit

struct ChatModelPicker: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @Binding private var chat: ChatConfiguration
    @State private var selectedModelID: UUID?
    
    private var localModels: [ModelFile] {
        appModel.modelFiles
            .filter { $0.isAvailableLocally && !$0.isMultimodalProjector }
            .sorted {
                $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
    }
    
    init(_ chat: Binding<ChatConfiguration>) {
        _chat = chat
        _selectedModelID = State(initialValue: chat.wrappedValue.modelFileID)
    }
    
    var body: some View {
        if localModels.isEmpty {
            LabeledContent("Model", value: chat.modelName)
        } else {
            Picker("Model", selection: $selectedModelID) {
                Text("No model selected")
                    .tag(UUID?.none)
                
                ForEach(localModels) {
                    Text($0.displayName)
                        .tag(Optional($0.id))
                }
            }
            .onChange(of: selectedModelID) { _, newValue in
                updateSelectedModel(newValue)
            }
        }
    }
    
    private func updateSelectedModel(_ modelID: UUID?) {
        guard let modelID else {
            chat.modelFileID = nil
            chat.modelName = "No model selected"
            return
        }
        
        guard let model = localModels.first(where: { $0.id == modelID }) else { return }
        
        chat.modelFileID = model.id
        chat.modelName = model.displayName
        chat.applyAutomaticTemplate(for: model)
    }
}
