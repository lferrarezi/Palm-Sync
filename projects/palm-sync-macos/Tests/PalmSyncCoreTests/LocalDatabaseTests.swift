import Foundation
import SQLite3
import Testing
@testable import PalmSyncCore

private struct Sample: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
}

struct LocalDatabaseTests {
    private func makeDatabase() throws -> LocalDatabase {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("palmsync-test-\(UUID().uuidString).sqlite")
        return try LocalDatabase(url: url)
    }

    @Test func savesAndLoadsItems() throws {
        let database = try makeDatabase()
        let items = [Sample(id: UUID(), name: "um"), Sample(id: UUID(), name: "dois")]
        try database.saveAll(items, in: .memos)
        let loaded = try database.loadAll(Sample.self, from: .memos)
        #expect(Set(loaded.map(\.id)) == Set(items.map(\.id)))
        #expect(try database.count(in: .memos) == 2)
    }

    @Test func saveIsUpsert() throws {
        let database = try makeDatabase()
        var item = Sample(id: UUID(), name: "antes")
        try database.save(item, in: .contacts)
        item.name = "depois"
        try database.save(item, in: .contacts)
        let loaded = try database.loadAll(Sample.self, from: .contacts)
        #expect(loaded == [item])
    }

    @Test func replaceAllSwapsCollectionAtomically() throws {
        let database = try makeDatabase()
        try database.saveAll([Sample(id: UUID(), name: "velho")], in: .tasks)
        let fresh = [Sample(id: UUID(), name: "novo")]
        try database.replaceAll(fresh, in: .tasks)
        #expect(try database.loadAll(Sample.self, from: .tasks) == fresh)
    }

    @Test func collectionsAreIsolated() throws {
        let database = try makeDatabase()
        try database.save(Sample(id: UUID(), name: "evento"), in: .events)
        #expect(try database.count(in: .contacts) == 0)
        #expect(try database.count(in: .events) == 1)
    }

    @Test func deleteRemovesSingleItem() throws {
        let database = try makeDatabase()
        let item = Sample(id: UUID(), name: "x")
        try database.save(item, in: .memos)
        try database.delete(id: "\(item.id)", from: .memos)
        #expect(try database.count(in: .memos) == 0)
    }

    @Test func corruptedJSONThrowsInsteadOfSilentlyDroppingRow() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("palmsync-corrupt-\(UUID().uuidString).sqlite")
        var database: LocalDatabase? = try LocalDatabase(url: url)
        let item = Sample(id: UUID(), name: "valid")
        try database?.save(item, in: .memos)
        database = nil

        var handle: OpaquePointer?
        #expect(sqlite3_open(url.path, &handle) == SQLITE_OK)
        defer { sqlite3_close(handle) }
        #expect(sqlite3_exec(handle, "UPDATE items SET json = X'00'", nil, nil, nil) == SQLITE_OK)

        let reopened = try LocalDatabase(url: url)
        #expect(throws: LocalDatabase.DatabaseError.self) {
            _ = try reopened.loadAll(Sample.self, from: .memos)
        }
    }

    @Test func upsertPreservesCollectionOrder() throws {
        let database = try makeDatabase()
        var first = Sample(id: UUID(), name: "first")
        let second = Sample(id: UUID(), name: "second")
        try database.save(first, in: .tasks)
        Thread.sleep(forTimeInterval: 0.01)
        try database.save(second, in: .tasks)

        first.name = "updated"
        try database.save(first, in: .tasks)
        #expect(try database.loadAll(Sample.self, from: .tasks) == [first, second])
    }
}
