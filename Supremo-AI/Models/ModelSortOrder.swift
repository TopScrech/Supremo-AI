enum ModelSortOrder: String, CaseIterable, Identifiable {
    case family, size
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .family: "Family"
        case .size: "Size"
        }
    }
}
