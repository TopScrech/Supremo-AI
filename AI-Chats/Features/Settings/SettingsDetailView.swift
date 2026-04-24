import SwiftUI

struct SettingsDetailView: View {
    let screen: SettingsScreen

    var body: some View {
        switch screen {
        case .models:
            ModelsView()
        
        case .downloads:
            DownloadModelsView()
        
        case .shortcuts:
            ShortcutsInfoView()
        
        case .fineTune:
            FineTuneView()
            
        case .about:
            AboutView()
        }
    }
}
