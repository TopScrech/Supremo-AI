import SwiftUI

struct GeneralSettings: View {
    @AppStorage("disableStatusBar") private var disableStatusBar = false
    @AppStorage("debugMode") private var debugMode = false

    var body: some View {
        Form {
            Section("Status Bar") {
                Toggle("Disable Status Bar", isOn: $disableStatusBar)
            }

            Section("Debug") {
                Toggle("Debug Mode", isOn: $debugMode)
            }
        }
    }
}
