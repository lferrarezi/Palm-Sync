import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case ptBR
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ptBR: "Português brasileiro"
        case .en: "English"
        }
    }
}

struct LocalizedLabel: Hashable, Codable {
    var ptBR: String
    var en: String

    func text(_ language: AppLanguage) -> String {
        switch language {
        case .ptBR: ptBR
        case .en: en
        }
    }
}

