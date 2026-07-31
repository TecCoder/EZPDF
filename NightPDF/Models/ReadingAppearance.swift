import Foundation

enum ReadingAppearance: String, Codable, CaseIterable, Identifiable {
    case original
    case night
    case softNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: return "Original"
        case .night: return "Nocturno"
        case .softNight: return "Nocturno suave"
        }
    }
}

