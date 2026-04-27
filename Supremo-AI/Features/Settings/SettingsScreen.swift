import Foundation

enum SettingsScreen: String, CaseIterable, Identifiable {
    case general, models, downloads, shortcuts, fineTune
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .general: "General"
        case .models: "Models"
        case .downloads: "Downloads"
        case .shortcuts: "Shortcuts"
        case .fineTune: "Fine Tune"
        }
    }
    
    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .models: "shippingbox"
        case .downloads: "arrow.down.circle"
        case .shortcuts: "sparkles"
        case .fineTune: "slider.horizontal.3"
        }
    }
}
