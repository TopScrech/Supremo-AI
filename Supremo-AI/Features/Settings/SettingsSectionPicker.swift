import SwiftUI

struct SettingsSectionPicker: View {
    @Binding var selectedScreen: SettingsScreen
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(SettingsScreen.allCases) { screen in
                    Button(screen.label, systemImage: screen.systemImage) {
                        selectedScreen = screen
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(selectedScreen == screen ? .accentColor : .secondary)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}
