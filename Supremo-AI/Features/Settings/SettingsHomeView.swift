import SwiftUI

struct SettingsHomeView: View {
    @Binding var selectedScreen: SettingsScreen
    
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            List(SettingsScreen.allCases, selection: $selectedScreen) {
                Label($0.label, systemImage: $0.systemImage)
                    .tag($0)
            }
            .navigationTitle("Settings")
        } detail: {
            SettingsDetailView(screen: selectedScreen)
        }
        .frame(minWidth: 720, minHeight: 520)
        #else
        settingsContent
        #endif
    }
    
    private var settingsContent: some View {
        VStack(spacing: 0) {
            SettingsSectionPicker($selectedScreen)
                .padding()
            
            SettingsDetailView(screen: selectedScreen)
        }
        .navigationTitle("Settings")
    }
}
