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
                title: "Sincronismo local",
                status: .syncing,
                summary: "Backup, agenda/calendar, contatos/contacts, tarefas/tasks e notas/memos",
                changes: 0
            ),
            at: 0
        )

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1))
            devices[0].state = .ready
            devices[0].lastSync = .now
            syncRuns[0].status = .ready
            syncRuns[0].summary = "Backup criado / backup created, 12 itens/items revisados"
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
            userID: "Aguardando HotSync / Waiting for HotSync",
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
                    userID: "Aguardando HotSync / Waiting for HotSync",
                    connection: "USB cable",
                    lastSync: nil,
                    state: .idle,
                    battery: 0
                )
            ],
            events: [
                CalendarItem(id: UUID(), title: "Revisar agenda do Palm / Review Palm calendar", date: now, durationMinutes: 45, location: "Local", source: .palm, needsReview: false),
                CalendarItem(id: UUID(), title: "Consulta importada / Imported appointment", date: Calendar.current.date(byAdding: .hour, value: 3, to: now) ?? now, durationMinutes: 30, location: "Google Calendar", source: .google, needsReview: true),
                CalendarItem(id: UUID(), title: "Backup semanal / Weekly backup", date: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now, durationMinutes: 20, location: "Mac", source: .local, needsReview: false),
                CalendarItem(id: UUID(), title: "Aniversario familiar / Family birthday", date: Calendar.current.date(byAdding: .day, value: 2, to: now) ?? now, durationMinutes: 1440, location: "iCloud", source: .iCloud, needsReview: false)
            ],
            contacts: [
                ContactItem(id: UUID(), name: "Ana Pereira", company: "Casa / Home", phone: "+55 11 99999-0101", email: "ana@example.com", source: .palm, needsReview: false),
                ContactItem(id: UUID(), name: "Carlos Mendes", company: "Trabalho / Work", phone: "+55 11 98888-0202", email: "carlos@example.com", source: .google, needsReview: true),
                ContactItem(id: UUID(), name: "Marina Costa", company: "iCloud", phone: "+55 11 97777-0303", email: "marina@example.com", source: .iCloud, needsReview: false)
            ],
            tasks: [
                TaskItem(id: UUID(), title: "Testar palm-probe com cradle USB / Test palm-probe with USB cradle", dueDate: now, priority: 1, isDone: false, source: .local),
                TaskItem(id: UUID(), title: "Separar fixtures PDB reais / Prepare real PDB fixtures", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now), priority: 2, isDone: false, source: .palm),
                TaskItem(id: UUID(), title: "Mapear campos de contato / Map contact fields", dueDate: nil, priority: 3, isDone: true, source: .google)
            ],
            memos: [
                MemoItem(id: UUID(), title: "Cabos e cradles / Cables and cradles", body: "Verificar adaptadores USB serial e drivers reconhecidos pelo macOS. / Check USB serial adapters and drivers recognized by macOS.", updatedAt: now, category: "Hardware", source: .local),
                MemoItem(id: UUID(), title: "Regras de conflito / Conflict rules", body: "Nunca sobrescrever o Palm sem snapshot do banco original. / Never overwrite the Palm without a snapshot of the original database.", updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now, category: "Sync", source: .palm),
                MemoItem(id: UUID(), title: "Campos modernos / Modern fields", body: "Google e iCloud aceitam mais telefones, emails e metadados do que AddressDB. / Google and iCloud support more phones, emails, and metadata than AddressDB.", updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now, category: "Mapeamento / Mapping", source: .google)
            ],
            syncRuns: [
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .hour, value: -22, to: now) ?? now, title: "HotSync de referencia / Reference HotSync", status: .ready, summary: "Agenda/calendar, contatos/contacts, tarefas/tasks e notas/memos", changes: 18),
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now, title: "Importacao PDB / PDB import", status: .warning, summary: "2 contatos precisam de revisao / 2 contacts need review", changes: 43),
                SyncRun(id: UUID(), startedAt: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now, title: "Backup inicial / Initial backup", status: .ready, summary: "Snapshot completo criado / Full snapshot created", changes: 164)
            ],
            accounts: [
                IntegrationAccount(id: UUID(), provider: "Google", symbol: "g.circle", status: .warning, detail: "OAuth pendente para escrita / OAuth pending for writes", enabledCollections: ["Agenda", "Contatos"]),
                IntegrationAccount(id: UUID(), provider: "iCloud", symbol: "icloud", status: .idle, detail: "CalDAV/CardDAV ainda nao conectado / not connected yet", enabledCollections: ["Agenda", "Contatos"]),
                IntegrationAccount(id: UUID(), provider: "Mac local / Local Mac", symbol: "macbook", status: .ready, detail: "Banco SQLite local ativo / Local SQLite database active", enabledCollections: ["Agenda", "Contatos", "Tarefas", "Notas"])
            ]
        )
    }
}
