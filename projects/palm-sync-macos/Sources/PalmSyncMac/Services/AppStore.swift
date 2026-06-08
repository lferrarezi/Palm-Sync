import Foundation
import Observation

@Observable
@MainActor
final class AppStore {
    var selectedSection: AppSection = .dashboard
    var language: AppLanguage = .ptBR
    var selectedDeviceID: PalmDevice.ID?
    var searchText = ""
    var isInspectorPresented = true
    var devices: [PalmDevice]
    var events: [CalendarItem]
    var contacts: [ContactItem]
    var tasks: [TaskItem]
    var memos: [MemoItem]
    var syncRuns: [SyncRun]
    var accounts: [IntegrationAccount]

    init(
        devices: [PalmDevice],
        events: [CalendarItem],
        contacts: [ContactItem],
        tasks: [TaskItem],
        memos: [MemoItem],
        syncRuns: [SyncRun],
        accounts: [IntegrationAccount]
    ) {
        self.devices = devices
        self.events = events
        self.contacts = contacts
        self.tasks = tasks
        self.memos = memos
        self.syncRuns = syncRuns
        self.accounts = accounts
        self.selectedDeviceID = devices.first?.id
    }

    var selectedDevice: PalmDevice? {
        guard let selectedDeviceID else { return devices.first }
        return devices.first { $0.id == selectedDeviceID }
    }

    var unresolvedCount: Int {
        events.filter(\.needsReview).count + contacts.filter(\.needsReview).count
    }

    var pendingChanges: Int {
        syncRuns.first?.changes ?? 0
    }

    func startLocalSyncSimulation() {
        guard !devices.isEmpty else { return }
        devices[0].state = .syncing
        syncRuns.insert(
            SyncRun(
                id: UUID(),
                startedAt: .now,
                title: LocalizedLabel(ptBR: "Sincronismo local", en: "Local sync"),
                status: .syncing,
                summary: LocalizedLabel(ptBR: "Backup, agenda, contatos, tarefas e notas", en: "Backup, calendar, contacts, tasks, and memos"),
                changes: 0
            ),
            at: 0
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            devices[0].state = .ready
            devices[0].lastSync = .now
            syncRuns[0].status = .ready
            syncRuns[0].summary = LocalizedLabel(ptBR: "Backup criado, 12 itens revisados", en: "Backup created, 12 items reviewed")
            syncRuns[0].changes = 12
        }
    }

    func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }
}

extension AppStore {
    static var preview: AppStore {
        let now = Date()
        let palmLifeDrive = PalmDevice(
            id: UUID(),
            name: "LifeDrive",
            model: "Palm OS 5.x",
            userID: LocalizedLabel(ptBR: "Aguardando HotSync", en: "Waiting for HotSync"),
            connection: "USB cradle/cable",
            lastSync: nil,
            state: .idle,
            battery: 0
        )

        return AppStore(
            devices: [
                palmLifeDrive,
                PalmDevice(
                    id: UUID(),
                    name: "Zire 22",
                    model: "Palm OS 5.x",
                    userID: LocalizedLabel(ptBR: "Aguardando HotSync", en: "Waiting for HotSync"),
                    connection: "USB cable",
                    lastSync: nil,
                    state: .idle,
                    battery: 0
                )
            ],
            events: [
                CalendarItem(id: UUID(), title: LocalizedLabel(ptBR: "Revisar agenda do Palm", en: "Review Palm calendar"), date: now, durationMinutes: 45, location: "Local", source: .palm, needsReview: false),
                CalendarItem(id: UUID(), title: LocalizedLabel(ptBR: "Consulta importada", en: "Imported appointment"), date: Calendar.current.date(byAdding: .hour, value: 3, to: now) ?? now, durationMinutes: 30, location: "Google Calendar", source: .google, needsReview: true),
                CalendarItem(id: UUID(), title: LocalizedLabel(ptBR: "Backup semanal", en: "Weekly backup"), date: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now, durationMinutes: 20, location: "Mac", source: .local, needsReview: false),
                CalendarItem(id: UUID(), title: LocalizedLabel(ptBR: "Aniversario familiar", en: "Family birthday"), date: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now, durationMinutes: 1440, location: "iCloud", source: .iCloud, needsReview: false)
            ],
            contacts: [
                ContactItem(id: UUID(), name: "Ana Pereira", company: LocalizedLabel(ptBR: "Casa", en: "Home"), phone: "+55 11 99999-0101", email: "ana@example.com", source: .palm, needsReview: false),
                ContactItem(id: UUID(), name: "Carlos Mendes", company: LocalizedLabel(ptBR: "Trabalho", en: "Work"), phone: "+55 11 98888-0202", email: "carlos@example.com", source: .google, needsReview: true),
                ContactItem(id: UUID(), name: "Marina Costa", company: LocalizedLabel(ptBR: "iCloud", en: "iCloud"), phone: "+55 11 97777-0303", email: "marina@example.com", source: .iCloud, needsReview: false)
            ],
            tasks: [
                TaskItem(id: UUID(), title: LocalizedLabel(ptBR: "Testar palm-probe com cradle USB", en: "Test palm-probe with USB cradle"), dueDate: now, priority: 1, isDone: false, source: .local),
                TaskItem(id: UUID(), title: LocalizedLabel(ptBR: "Separar fixtures PDB reais", en: "Prepare real PDB fixtures"), dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now), priority: 2, isDone: false, source: .palm),
                TaskItem(id: UUID(), title: LocalizedLabel(ptBR: "Mapear campos de contato", en: "Map contact fields"), dueDate: nil, priority: 3, isDone: true, source: .google)
            ],
            memos: [
                MemoItem(id: UUID(), title: LocalizedLabel(ptBR: "Cabos e cradles", en: "Cables and cradles"), body: LocalizedLabel(ptBR: "Verificar adaptadores USB serial e drivers reconhecidos pelo macOS.", en: "Check USB serial adapters and drivers recognized by macOS."), updatedAt: now, category: LocalizedLabel(ptBR: "Hardware", en: "Hardware"), source: .local),
                MemoItem(id: UUID(), title: LocalizedLabel(ptBR: "Regras de conflito", en: "Conflict rules"), body: LocalizedLabel(ptBR: "Nunca sobrescrever o Palm sem snapshot do banco original.", en: "Never overwrite the Palm without a snapshot of the original database."), updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now, category: LocalizedLabel(ptBR: "Sync", en: "Sync"), source: .palm),
                MemoItem(id: UUID(), title: LocalizedLabel(ptBR: "Campos modernos", en: "Modern fields"), body: LocalizedLabel(ptBR: "Google e iCloud aceitam mais telefones, emails e metadados do que AddressDB.", en: "Google and iCloud support more phones, emails, and metadata than AddressDB."), updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now, category: LocalizedLabel(ptBR: "Mapeamento", en: "Mapping"), source: .google)
            ],
            syncRuns: [
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .hour, value: -22, to: now) ?? now, title: LocalizedLabel(ptBR: "HotSync de referencia", en: "Reference HotSync"), status: .ready, summary: LocalizedLabel(ptBR: "Agenda, contatos, tarefas e notas", en: "Calendar, contacts, tasks, and memos"), changes: 18),
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now, title: LocalizedLabel(ptBR: "Importacao PDB", en: "PDB import"), status: .warning, summary: LocalizedLabel(ptBR: "2 contatos precisam de revisao", en: "2 contacts need review"), changes: 43),
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now, title: LocalizedLabel(ptBR: "Backup inicial", en: "Initial backup"), status: .ready, summary: LocalizedLabel(ptBR: "Snapshot completo criado", en: "Full snapshot created"), changes: 164)
            ],
            accounts: [
                IntegrationAccount(id: UUID(), provider: LocalizedLabel(ptBR: "Google", en: "Google"), symbol: "g.circle", status: .warning, detail: LocalizedLabel(ptBR: "OAuth pendente para escrita", en: "OAuth pending for writes"), enabledCollections: ["Agenda", "Contatos"]),
                IntegrationAccount(id: UUID(), provider: LocalizedLabel(ptBR: "iCloud", en: "iCloud"), symbol: "icloud", status: .idle, detail: LocalizedLabel(ptBR: "CalDAV/CardDAV ainda nao conectado", en: "CalDAV/CardDAV not connected yet"), enabledCollections: ["Agenda", "Contatos"]),
                IntegrationAccount(id: UUID(), provider: LocalizedLabel(ptBR: "Mac local", en: "Local Mac"), symbol: "macbook", status: .ready, detail: LocalizedLabel(ptBR: "Banco SQLite local ativo", en: "Local SQLite database active"), enabledCollections: ["Agenda", "Contatos", "Tarefas", "Notas"])
            ]
        )
    }
}
