import SwiftUI

struct GeneralSettings: View {
    @AppStorage("disableStatusBar") private var disableStatusBar = false
    
    var body: some View {
        Form {
            Section("Status Bar") {
                Toggle("Disable Status Bar", isOn: $disableStatusBar)
            }
        }
    }
}
