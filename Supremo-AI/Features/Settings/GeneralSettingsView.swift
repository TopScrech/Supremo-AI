import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("disableStatusBar") private var disableStatusBar = false
    
    var body: some View {
        Form {
            Section("Status Bar") {
                Toggle("Disable Status Bar", isOn: $disableStatusBar)
            }
        }
        .navigationTitle("General")
    }
}
