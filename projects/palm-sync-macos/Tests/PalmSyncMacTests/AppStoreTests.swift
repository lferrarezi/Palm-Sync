import Foundation
import PalmSyncCore
import Testing
@testable import PalmSyncMac

@MainActor
private func makeStore() -> AppStore {
    AppStore.preview
}

private func makeDatabase() throws -> LocalDatabase {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("palmsync-store-test-\(UUID().uuidString).sqlite")
    return try LocalDatabase(url: url)
}

private func makeMemoPDB(texts: [String]) -> Data {
    let records = texts.map { text -> Data in
        var data = Data(text.utf8)
        data.append(0)
        return data
    }
    var data = Data()
    var name = Array("MemoDB".utf8)
    name.append(contentsOf: Array(repeating: 0, count: 32 - name.count))
    data.append(contentsOf: name)
    data.append(contentsOf: [0, 0, 0, 1])
    data.append(contentsOf: Array(repeating: 0, count: 24))
    data.append(contentsOf: Array("DATA".utf8))
    data.append(contentsOf: Array("memo".utf8))
    data.append(contentsOf: Array(repeating: 0, count: 8))
    data.append(contentsOf: [0, UInt8(records.count)])
    var offset = 78 + records.count * 8
    for index in records.indices {
        data.append(contentsOf: [
            UInt8((offset >> 24) & 0xFF), UInt8((offset >> 16) & 0xFF),
            UInt8((offset >> 8) & 0xFF), UInt8(offset & 0xFF),
            0, 0, 0, UInt8(index + 1)
        ])
        offset += records[index].count
    }
    records.forEach { data.append($0) }
    return data
}

@MainActor
struct AppStoreTests {
    @Test func emptySearchReturnsEverything() {
        let store = makeStore()
        store.searchText = ""
        #expect(store.filteredContacts.count == store.contacts.count)
        #expect(store.filteredEvents.count == store.events.count)
        #expect(store.filteredTasks.count == store.tasks.count)
        #expect(store.filteredMemos.count == store.memos.count)
    }

    @Test func searchFiltersContactsByNameAndEmail() {
        let store = makeStore()
        store.searchText = "ana"
        #expect(store.filteredContacts.contains { $0.name == "Ana Pereira" })

        store.searchText = "marina@example.com"
        #expect(store.filteredContacts.count == 1)
        #expect(store.filteredContacts.first?.name == "Marina Costa")
    }

    @Test func searchIsCaseInsensitiveAndTrimmed() {
        let store = makeStore()
        store.searchText = "  ANA  "
        #expect(store.filteredContacts.contains { $0.name == "Ana Pereira" })
    }

    @Test func toggleTaskFlipsCompletion() {
        let store = makeStore()
        let task = store.tasks[0]
        let original = task.isDone
        store.toggleTask(task)
        #expect(store.tasks[0].isDone == !original)
    }

    @Test func syncSimulationMarksSelectedDeviceSyncingAndInsertsRun() {
        let store = makeStore()
        let runCount = store.syncRuns.count
        store.startLocalSyncSimulation()
        #expect(store.syncRuns.count == runCount + 1)
        #expect(store.syncRuns.first?.status == .syncing)
        #expect(store.selectedDevice?.state == .syncing)

        // Re-entrancy guard: a second start while syncing must not add another run.
        store.startLocalSyncSimulation()
        #expect(store.syncRuns.count == runCount + 1)
    }

    @Test func unresolvedCountSumsEventsAndContactsNeedingReview() {
        let store = makeStore()
        let expected = store.events.filter(\.needsReview).count
            + store.contacts.filter(\.needsReview).count
        #expect(store.unresolvedCount == expected)
    }

    @Test func taskCompletionSurvivesReload() throws {
        let database = try makeDatabase()
        let first = makeStore()
        try first.attachDatabase(database)
        let task = first.tasks[0]
        first.toggleTask(task)

        let second = makeStore()
        try second.attachDatabase(database)
        #expect(second.tasks.first(where: { $0.id == task.id })?.isDone == !task.isDone)
    }

    @Test func intentionallyEmptyCollectionIsNotReseeded() throws {
        let database = try makeDatabase()
        let first = makeStore()
        try first.attachDatabase(database)
        try database.deleteAll(in: .tasks)

        let second = makeStore()
        try second.attachDatabase(database)
        #expect(second.tasks.isEmpty)
    }

    @Test func syncHistoryLoadsFromDatabase() throws {
        let database = try makeDatabase()
        let run = SyncRun(
            id: UUID(),
            startedAt: .now,
            title: LocalizedLabel(ptBR: "Persistido", en: "Persisted"),
            status: .ready,
            summary: LocalizedLabel(ptBR: "Teste", en: "Test"),
            changes: 7
        )
        try database.save(run, in: .syncRuns)

        let store = makeStore()
        try store.attachDatabase(database)
        #expect(store.syncRuns.count == 1)
        #expect(store.syncRuns.first?.id == run.id)
        #expect(store.syncRuns.first?.status == run.status)
        #expect(store.syncRuns.first?.changes == run.changes)
    }

    @Test func reimportReportsOnlyNewRecordsAndDedupesWithinFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("memo-\(UUID().uuidString).pdb")
        try makeMemoPDB(texts: ["Nota\nCorpo", "Nota\nCorpo"]).write(to: url)
        let store = makeStore()
        let initialCount = store.memos.count

        store.importPalmBackup(from: url)
        #expect(store.memos.count == initialCount + 1)
        #expect(store.syncRuns.first?.changes == 1)

        store.importPalmBackup(from: url)
        #expect(store.memos.count == initialCount + 1)
        #expect(store.syncRuns.first?.changes == 0)
    }

    @Test func reimportUpdatesExistingPalmRecordWithoutDuplicating() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("memo-update-\(UUID().uuidString).pdb")
        let store = makeStore()
        let initialCount = store.memos.count

        try makeMemoPDB(texts: ["Nota Palm\nTexto antigo"]).write(to: url)
        store.importPalmBackup(from: url)
        let importedID = store.memos.first { $0.title.ptBR == "Nota Palm" }?.id
        #expect(importedID != nil)

        try makeMemoPDB(texts: ["Nota Palm\nTexto novo"]).write(to: url)
        store.importPalmBackup(from: url)

        #expect(store.memos.count == initialCount + 1)
        #expect(store.memos.first { $0.id == importedID }?.body.ptBR == "Texto novo")
        #expect(store.syncRuns.first?.changes == 1)
    }
}

struct LocalizationTests {
    @Test func localizedLabelReturnsLanguageSpecificText() {
        let label = LocalizedLabel(ptBR: "Painel", en: "Dashboard")
        #expect(label.text(.ptBR) == "Painel")
        #expect(label.text(.en) == "Dashboard")
    }

    @Test func everySectionHasTitlesInBothLanguages() {
        for section in AppSection.allCases {
            #expect(!section.title(for: .ptBR).isEmpty)
            #expect(!section.title(for: .en).isEmpty)
        }
    }
}
