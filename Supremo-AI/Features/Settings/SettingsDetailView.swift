import SwiftUI

struct SettingsDetailView: View {
    let screen: SettingsScreen
    
    var body: some View {
        switch screen {
        case .general: GeneralSettingsView()
        case .models: ModelsView()
        case .downloads: DownloadableModelList()
        case .shortcuts: ShortcutsInfoView()
        case .fineTune: FineTuneView()
        }
    }
}
