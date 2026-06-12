import Foundation
import Observation
import OSLog
import PalmSyncCore

@Observable
@MainActor
final class AppStore {
    private enum PreferenceKey {
        static let language = "app.language"
        static let inspectorPresented = "app.inspectorPresented"
        static let selectedDeviceID = "app.selectedDeviceID"
    }

    var selectedSection: AppSection = .dashboard
    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: PreferenceKey.language) }
    }
    var selectedDeviceID: PalmDevice.ID? {
        didSet {
            UserDefaults.standard.set(selectedDeviceID?.uuidString, forKey: PreferenceKey.selectedDeviceID)
        }
    }
    var searchText = ""
    var isInspectorPresented: Bool {
        didSet { UserDefaults.standard.set(isInspectorPresented, forKey: PreferenceKey.inspectorPresented) }
    }
    var devices: [PalmDevice]
    var events: [CalendarItem]
    var contacts: [ContactItem]
    var tasks: [TaskItem]
    var memos: [MemoItem]
    var syncRuns: [SyncRun]
    var accounts: [IntegrationAccount]
    var lastImportSummary: LocalizedLabel?

    @ObservationIgnored private var database: LocalDatabase?
    @ObservationIgnored private var isDatabaseAttached = false
    @ObservationIgnored private let logger = Logger(subsystem: "br.com.ferrarezi.palm-sync", category: "store")

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
        let defaults = UserDefaults.standard
        let savedDeviceID = defaults.string(forKey: PreferenceKey.selectedDeviceID).flatMap(UUID.init(uuidString:))
        self.selectedDeviceID = devices.contains { $0.id == savedDeviceID } ? savedDeviceID : devices.first?.id
        self.language = defaults.string(forKey: PreferenceKey.language)
            .flatMap(AppLanguage.init(rawValue:)) ?? .ptBR
        self.isInspectorPresented = defaults.object(forKey: PreferenceKey.inspectorPresented) as? Bool ?? true
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
        guard let device = selectedDevice ?? devices.first,
              let deviceIndex = devices.firstIndex(where: { $0.id == device.id }),
              devices[deviceIndex].state != .syncing else { return }

        devices[deviceIndex].state = .syncing
        let run = SyncRun(
            id: UUID(),
            startedAt: .now,
            title: LocalizedLabel(ptBR: "Sincronismo local", en: "Local sync"),
            status: .syncing,
            summary: LocalizedLabel(ptBR: "Backup, agenda, contatos, tarefas e notas", en: "Backup, calendar, contacts, tasks, and memos"),
            changes: 0
        )
        syncRuns.insert(run, at: 0)

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            guard let self else { return }
            if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                self.devices[index].state = .ready
                self.devices[index].lastSync = .now
            }
            if let index = self.syncRuns.firstIndex(where: { $0.id == run.id }) {
                self.syncRuns[index].status = .ready
                self.syncRuns[index].summary = LocalizedLabel(ptBR: "Backup criado, 12 itens revisados", en: "Backup created, 12 items reviewed")
                self.syncRuns[index].changes = 12
                self.persist(self.syncRuns[index], in: .syncRuns)
            }
        }
        persist(run, in: .syncRuns)
    }

    func toggleTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
        persist(tasks[index], in: .tasks)
    }
}

// MARK: - Persistence

extension AppStore {
    /// Loads persisted collections from SQLite; on first run, seeds the
    /// database with the current (sample) content.
    func attachDatabase() {
        do {
            try attachDatabase(LocalDatabase(url: LocalDatabase.defaultURL()))
        } catch {
            logger.error("Local database unavailable: \(error.localizedDescription)")
        }
    }

    func attachDatabase(_ database: LocalDatabase) throws {
        guard !isDatabaseAttached else { return }

        struct BootstrapMarker: Codable, Identifiable {
            let id: String
            let schemaVersion: Int
        }

        let collections: [LocalDatabase.Collection] = [.events, .contacts, .tasks, .memos, .syncRuns]
        let isInitialized = try database.count(in: .metadata) > 0
        let hasExistingData = try collections.contains { try database.count(in: $0) > 0 }

        if !isInitialized && !hasExistingData {
            try database.replaceAll(events, in: .events)
            try database.replaceAll(contacts, in: .contacts)
            try database.replaceAll(tasks, in: .tasks)
            try database.replaceAll(memos, in: .memos)
            try database.replaceAll(syncRuns, in: .syncRuns)
            logger.info("Seeded local database")
        }

        if !isInitialized {
            try database.save(BootstrapMarker(id: "bootstrap", schemaVersion: 1), in: .metadata)
        }

        let loadedEvents = try database.loadAll(CalendarItem.self, from: .events)
        let loadedContacts = try database.loadAll(ContactItem.self, from: .contacts)
        let loadedTasks = try database.loadAll(TaskItem.self, from: .tasks)
        let loadedMemos = try database.loadAll(MemoItem.self, from: .memos)
        let loadedSyncRuns = try database.loadAll(SyncRun.self, from: .syncRuns)

        self.database = database
        events = loadedEvents
        contacts = loadedContacts
        tasks = loadedTasks
        memos = loadedMemos
        syncRuns = loadedSyncRuns
        isDatabaseAttached = true
        logger.info("Loaded collections from local database")
    }

    private func persist<T: Codable & Identifiable>(_ items: [T], in collection: LocalDatabase.Collection) {
        guard let database else { return }
        do {
            try database.replaceAll(items, in: collection)
        } catch {
            logger.error("Persist failed for \(collection.rawValue): \(error.localizedDescription)")
        }
    }

    private func persist<T: Codable & Identifiable>(_ item: T, in collection: LocalDatabase.Collection) {
        guard let database else { return }
        do {
            try database.save(item, in: collection)
        } catch {
            logger.error("Persist failed for \(collection.rawValue): \(error.localizedDescription)")
        }
    }
}

// MARK: - PDB import

extension AppStore {
    /// Imports a classic Palm .pdb backup file into the local collections.
    func importPalmBackup(from url: URL) {
        do {
            let needsScope = url.startAccessingSecurityScopedResource()
            defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

            let file = try PDBFile(data: Data(contentsOf: url))
            let deviceNamespace = selectedDevice?.id.uuidString ?? "unassigned"
            let sourcePrefix = "\(deviceNamespace):\(file.creator):\(file.type)"
            let sourceDate = file.modificationDate ?? file.creationDate ?? Date(timeIntervalSince1970: 0)
            let imported = apply(
                content: PalmDatabaseContent(file: file),
                sourcePrefix: sourcePrefix,
                sourceDate: sourceDate
            )

            lastImportSummary = LocalizedLabel(
                ptBR: "\(imported) itens importados de \(file.name)",
                en: "\(imported) items imported from \(file.name)"
            )
            syncRuns.insert(
                SyncRun(
                    id: UUID(),
                    startedAt: .now,
                    title: LocalizedLabel(ptBR: "Importação PDB", en: "PDB import"),
                    status: imported > 0 ? .ready : .warning,
                    summary: lastImportSummary ?? LocalizedLabel(ptBR: "Importação", en: "Import"),
                    changes: imported
                ),
                at: 0
            )
            if let run = syncRuns.first {
                persist(run, in: .syncRuns)
            }
            logger.info("Imported \(imported) records from PDB \(file.name, privacy: .public)")
        } catch {
            lastImportSummary = LocalizedLabel(
                ptBR: "Falha ao importar: \(error.localizedDescription)",
                en: "Import failed: \(error.localizedDescription)"
            )
            logger.error("PDB import failed: \(error.localizedDescription)")
        }
    }

    private func apply(content: PalmDatabaseContent, sourcePrefix: String, sourceDate: Date) -> Int {
        switch content {
        case let .addresses(records):
            let items = records.map { entry in
                let record = entry.value
                let sourceRecordID = importedRecordID(prefix: sourcePrefix, uniqueID: entry.uniqueID)
                let email = record.phones.first(where: { $0.contains("@") }) ?? ""
                let phone = record.phones.first(where: { !$0.contains("@") }) ?? ""
                let fallbackID = contacts.first {
                    $0.sourceRecordID == nil
                        && ($0.name, $0.phone, $0.email) == (record.displayName, phone, email)
                }?.id
                return ContactItem(
                    id: existingID(for: sourceRecordID, in: contacts) ?? fallbackID ?? UUID(),
                    name: record.displayName,
                    company: LocalizedLabel(ptBR: record.company ?? "", en: record.company ?? ""),
                    phone: phone,
                    email: email,
                    source: .palm,
                    needsReview: false,
                    sourceRecordID: sourceRecordID
                )
            }
            let result = mergingImported(items, into: contacts) { ($0.name, $0.phone, $0.email) == ($1.name, $1.phone, $1.email) }
            contacts = result.items
            persist(contacts, in: .contacts)
            return result.insertedCount

        case let .memos(records):
            let items = records.map { entry in
                let record = entry.value
                let sourceRecordID = importedRecordID(prefix: sourcePrefix, uniqueID: entry.uniqueID)
                let title = LocalizedLabel(ptBR: record.title, en: record.title)
                let body = LocalizedLabel(ptBR: record.body, en: record.body)
                let fallbackID = memos.first {
                    $0.sourceRecordID == nil && $0.title == title && $0.body == body
                }?.id
                return MemoItem(
                    id: existingID(for: sourceRecordID, in: memos) ?? fallbackID ?? UUID(),
                    title: title,
                    body: body,
                    updatedAt: sourceDate,
                    category: LocalizedLabel(ptBR: entry.category ?? "Palm", en: entry.category ?? "Palm"),
                    source: .palm,
                    sourceRecordID: sourceRecordID
                )
            }
            let result = mergingImported(items, into: memos) { $0.title == $1.title && $0.body == $1.body }
            memos = result.items
            persist(memos, in: .memos)
            return result.insertedCount

        case let .todos(records):
            let items = records.map { entry in
                let record = entry.value
                let sourceRecordID = importedRecordID(prefix: sourcePrefix, uniqueID: entry.uniqueID)
                let title = LocalizedLabel(ptBR: record.description, en: record.description)
                let fallbackID = tasks.first {
                    $0.sourceRecordID == nil && $0.title == title && $0.dueDate == record.dueDate
                }?.id
                return TaskItem(
                    id: existingID(for: sourceRecordID, in: tasks) ?? fallbackID ?? UUID(),
                    title: title,
                    dueDate: record.dueDate,
                    priority: max(1, record.priority),
                    isDone: record.isCompleted,
                    source: .palm,
                    sourceRecordID: sourceRecordID
                )
            }
            let result = mergingImported(items, into: tasks) { $0.title == $1.title && $0.dueDate == $1.dueDate }
            tasks = result.items
            persist(tasks, in: .tasks)
            return result.insertedCount

        case let .datebook(records):
            let items = records.compactMap { entry -> CalendarItem? in
                let record = entry.value
                guard let start = record.startDate ?? record.date else { return nil }
                let sourceRecordID = importedRecordID(prefix: sourcePrefix, uniqueID: entry.uniqueID)
                let title = LocalizedLabel(ptBR: record.description, en: record.description)
                let fallbackID = events.first {
                    $0.sourceRecordID == nil && $0.title == title && $0.date == start
                }?.id
                return CalendarItem(
                    id: existingID(for: sourceRecordID, in: events) ?? fallbackID ?? UUID(),
                    title: title,
                    date: start,
                    durationMinutes: record.durationMinutes,
                    location: "",
                    notes: record.note,
                    source: .palm,
                    needsReview: false,
                    sourceRecordID: sourceRecordID
                )
            }
            let result = mergingImported(items, into: events) { $0.title == $1.title && $0.date == $1.date }
            events = result.items
            persist(events, in: .events)
            return result.insertedCount

        case .unknown:
            return 0
        }
    }

    private func mergingImported<T: Identifiable & Equatable>(
        _ new: [T],
        into existing: [T],
        isDuplicate: (T, T) -> Bool
    ) -> (items: [T], insertedCount: Int) where T.ID: Equatable {
        var result = existing
        var insertedCount = 0
        for item in new {
            if let index = result.firstIndex(where: { $0.id == item.id }) {
                if result[index] != item {
                    result[index] = item
                    insertedCount += 1
                }
            } else if !result.contains(where: { isDuplicate($0, item) }) {
                result.append(item)
                insertedCount += 1
            }
        }
        return (result, insertedCount)
    }

    private func importedRecordID(prefix: String, uniqueID: UInt32) -> String? {
        uniqueID == 0 ? nil : "\(prefix):\(uniqueID)"
    }

    private func existingID<T: SourceRecordIdentifiable>(for sourceRecordID: String?, in items: [T]) -> T.ID? {
        guard let sourceRecordID else { return nil }
        return items.first { $0.sourceRecordID == sourceRecordID }?.id
    }
}

// MARK: - Search

extension AppStore {
    private var normalizedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matches(_ fields: String...) -> Bool {
        let query = normalizedQuery
        guard !query.isEmpty else { return true }
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    var filteredEvents: [CalendarItem] {
        events.filter { matches($0.title.text(language), $0.location, $0.notes ?? "") }
    }

    var filteredContacts: [ContactItem] {
        contacts.filter { matches($0.name, $0.company.text(language), $0.phone, $0.email) }
    }

    var filteredTasks: [TaskItem] {
        tasks.filter { matches($0.title.text(language)) }
    }

    var filteredMemos: [MemoItem] {
        memos.filter { matches($0.title.text(language), $0.body.text(language), $0.category.text(language)) }
    }
}

extension AppStore {
    private static let lifeDriveID = UUID(uuidString: "A941CC78-7895-4A84-9DBA-4FE4FB0F7F01") ?? UUID()
    private static let zire22ID = UUID(uuidString: "E217E022-7895-4A84-9DBA-4FE4FB0F7F02") ?? UUID()

    static var preview: AppStore {
        let now = Date()
        let palmLifeDrive = PalmDevice(
            id: lifeDriveID,
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
                    id: zire22ID,
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
