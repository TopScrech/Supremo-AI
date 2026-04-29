import SwiftUI

struct SettingsDetailView: View {
    private let screen: SettingsScreen
    
    init(_ screen: SettingsScreen) {
        self.screen = screen
    }
    
    var body: some View {
        switch screen {
        case .general: GeneralSettings()
        case .models: ModelsView()
        case .downloads: DownloadableModelList()
        case .shortcuts: ShortcutsInfoView()
        case .fineTune: FineTuneView()
        }
    }
}
