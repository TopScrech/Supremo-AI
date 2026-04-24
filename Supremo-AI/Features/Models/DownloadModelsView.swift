import SwiftUI

struct DownloadModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    var body: some View {
        List {
            Text("When the first model finishes, it is assigned to the current chat automatically")
            
            ForEach(appModel.downloadableModelFamilies) { family in
                Section(family.name) {
                    ForEach(family.models) {
                        DownloadableModelCard($0)
                    }
                }
            }
        }
        .navigationTitle("Downloads")
    }
}
