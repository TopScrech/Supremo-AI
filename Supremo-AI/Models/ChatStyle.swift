import Foundation

enum ChatStyle: String, Codable, CaseIterable, Identifiable {
    case balanced, compact, transcript
    
    var id: String { rawValue }
    
    var label: String {
        rawValue.capitalized
    }
}
