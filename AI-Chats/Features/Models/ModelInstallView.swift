import SwiftUI

struct ModelInstallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedScreen = SettingsScreen.downloads

    var body: some View {
        SettingsHomeView(selectedScreen: $selectedScreen)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        dismiss()
                    }
                }
            }
    }
}
