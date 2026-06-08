import Foundation
import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case agenda
    case contacts
    case tasks
    case memos
    case devices
    case sync
    case settings

    var id: String { rawValue }

    var title: String {
        title(for: .ptBR)
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .dashboard: LocalizedLabel(ptBR: "Painel", en: "Dashboard").text(language)
        case .agenda: LocalizedLabel(ptBR: "Agenda", en: "Calendar").text(language)
        case .contacts: LocalizedLabel(ptBR: "Contatos", en: "Contacts").text(language)
        case .tasks: LocalizedLabel(ptBR: "Tarefas", en: "Tasks").text(language)
        case .memos: LocalizedLabel(ptBR: "Notas", en: "Memos").text(language)
        case .devices: LocalizedLabel(ptBR: "Dispositivos", en: "Devices").text(language)
        case .sync: LocalizedLabel(ptBR: "Sincronismo", en: "Sync").text(language)
        case .settings: LocalizedLabel(ptBR: "Ajustes", en: "Settings").text(language)
        }
    }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .agenda: "calendar"
        case .contacts: "person.crop.circle"
        case .tasks: "checklist"
        case .memos: "note.text"
        case .devices: "palm"
        case .sync: "arrow.triangle.2.circlepath"
        case .settings: "gearshape"
        }
    }
}

enum SyncState: String, Codable {
    case idle
    case ready
    case syncing
    case warning
    case blocked

    var label: String {
        label(for: .ptBR)
    }

    func label(for language: AppLanguage) -> String {
        switch self {
        case .idle: LocalizedLabel(ptBR: "Ocioso", en: "Idle").text(language)
        case .ready: LocalizedLabel(ptBR: "Pronto", en: "Ready").text(language)
        case .syncing: LocalizedLabel(ptBR: "Sincronizando", en: "Syncing").text(language)
        case .warning: LocalizedLabel(ptBR: "Atenção", en: "Review").text(language)
        case .blocked: LocalizedLabel(ptBR: "Bloqueado", en: "Blocked").text(language)
        }
    }

    var color: Color {
        switch self {
        case .idle: .secondary
        case .ready: .green
        case .syncing: .blue
        case .warning: .orange
        case .blocked: .red
        }
    }
}

struct PalmDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var model: String
    var userID: String
    var connection: String
    var lastSync: Date?
    var state: SyncState
    var battery: Int
}

struct CalendarItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var durationMinutes: Int
    var location: String
    var source: SyncSource
    var needsReview: Bool
}

struct ContactItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var company: String
    var phone: String
    var email: String
    var source: SyncSource
    var needsReview: Bool
}

struct TaskItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var dueDate: Date?
    var priority: Int
    var isDone: Bool
    var source: SyncSource
}

struct MemoItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var updatedAt: Date
    var category: String
    var source: SyncSource
}

struct SyncSource: Hashable, Codable {
    var name: String
    var symbol: String
    var tintName: String

    static let palm = SyncSource(name: "Palm", symbol: "palm", tintName: "green")
    static let local = SyncSource(name: "Local", symbol: "internaldrive", tintName: "gray")
    static let google = SyncSource(name: "Google", symbol: "g.circle", tintName: "blue")
    static let iCloud = SyncSource(name: "iCloud", symbol: "icloud", tintName: "cyan")

    var tint: Color {
        switch tintName {
        case "green": .green
        case "blue": .blue
        case "cyan": .cyan
        default: .secondary
        }
    }
}

struct SyncRun: Identifiable, Hashable {
    let id: UUID
    var startedAt: Date
    var title: String
    var status: SyncState
    var summary: String
    var changes: Int
}

struct IntegrationAccount: Identifiable, Hashable {
    let id: UUID
    var provider: String
    var symbol: String
    var status: SyncState
    var detail: String
    var enabledCollections: Set<String>
}
