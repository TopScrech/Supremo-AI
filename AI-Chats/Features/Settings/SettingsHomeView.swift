import SwiftUI

struct SettingsHomeView: View {
    @Binding var selectedScreen: SettingsScreen

    var body: some View {
        VStack(spacing: 0) {
            SettingsSectionPicker(selectedScreen: $selectedScreen)
                .padding()

            SettingsDetailView(screen: selectedScreen)
        }
        .navigationTitle("Settings")
    }
}
