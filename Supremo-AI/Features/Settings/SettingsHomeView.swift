import SwiftUI

struct SettingsHomeView: View {
    @Binding private var selectedScreen: SettingsScreen
    
    init(_ selectedScreen: Binding<SettingsScreen>) {
        _selectedScreen = selectedScreen
    }
    
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
        TabView(selection: $selectedScreen) {
            ForEach(SettingsScreen.allCases) { screen in
                Tab(screen.label, systemImage: screen.systemImage, value: screen) {
                    SettingsDetailView(screen)
                }
            }
        }
        .navigationTitle(selectedScreen.label)
#endif
    }
}
