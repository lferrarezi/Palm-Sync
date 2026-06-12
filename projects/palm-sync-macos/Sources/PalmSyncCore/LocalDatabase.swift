import Foundation
import SQLite3

/// Local persistence: one SQLite file storing each item as a JSON document
/// keyed by (collection, id). Keeps the schema flexible while the domain
/// models evolve; collections map to Palm databases (events, contacts, tasks,
/// memos) plus sync metadata.
public final class LocalDatabase: @unchecked Sendable {
    public enum Collection: String, CaseIterable, Sendable {
        case events, contacts, tasks, memos, syncRuns, snapshots, metadata
    }

    public enum DatabaseError: Error, LocalizedError {
        case cannotOpen(String)
        case statementFailed(String)
        case decodingFailed(collection: String, id: String, message: String)

        public var errorDescription: String? {
            switch self {
            case let .cannotOpen(message): "Cannot open database: \(message)"
            case let .statementFailed(message): "Database operation failed: \(message)"
            case let .decodingFailed(collection, id, message):
                "Cannot decode \(collection)/\(id): \(message)"
            }
        }
    }

    private var handle: OpaquePointer?
    private let queue = DispatchQueue(label: "palm-sync.local-database")
    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// Default location: ~/Library/Application Support/PalmSync/palmsync.sqlite
    public static func defaultURL() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let directory = support.appendingPathComponent("PalmSync", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("palmsync.sqlite")
    }

    public init(url: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            throw DatabaseError.cannotOpen(message)
        }
        handle = db
        try execute("PRAGMA journal_mode=WAL")
        try execute("""
            CREATE TABLE IF NOT EXISTS items (
                collection TEXT NOT NULL,
                id TEXT NOT NULL,
                json BLOB NOT NULL,
                updated_at REAL NOT NULL,
                PRIMARY KEY (collection, id)
            )
            """)
    }

    deinit {
        sqlite3_close(handle)
    }

    public func save<T: Codable & Identifiable>(_ item: T, in collection: Collection) throws {
        try queue.sync {
            try saveLocked(item, in: collection)
        }
    }

    public func saveAll<T: Codable & Identifiable>(_ items: [T], in collection: Collection) throws {
        try queue.sync {
            try execute("BEGIN")
            do {
                for item in items { try saveLocked(item, in: collection) }
                try execute("COMMIT")
            } catch {
                try? execute("ROLLBACK")
                throw error
            }
        }
    }

    /// Replaces the whole collection atomically with the given items.
    public func replaceAll<T: Codable & Identifiable>(_ items: [T], in collection: Collection) throws {
        try queue.sync {
            try execute("BEGIN")
            do {
                try write("DELETE FROM items WHERE collection = ?") { statement in
                    sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
                }
                for item in items { try saveLocked(item, in: collection) }
                try execute("COMMIT")
            } catch {
                try? execute("ROLLBACK")
                throw error
            }
        }
    }

    private func saveLocked<T: Codable & Identifiable>(_ item: T, in collection: Collection) throws {
        let data = try JSONEncoder.palmSync.encode(item)
        try write(
            """
            INSERT INTO items (collection, id, json, updated_at) VALUES (?, ?, ?, ?)
            ON CONFLICT(collection, id) DO UPDATE SET json = excluded.json
            """
        ) { statement in
            sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
            sqlite3_bind_text(statement, 2, "\(item.id)", -1, Self.sqliteTransient)
            data.withUnsafeBytes { bytes in
                _ = sqlite3_bind_blob(statement, 3, bytes.baseAddress, Int32(bytes.count), Self.sqliteTransient)
            }
            sqlite3_bind_double(statement, 4, Date().timeIntervalSince1970)
        }
    }

    public func loadAll<T: Codable>(_ type: T.Type, from collection: Collection) throws -> [T] {
        try queue.sync {
            var results: [T] = []
            try query("SELECT id, json FROM items WHERE collection = ? ORDER BY updated_at, id") { statement in
                sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
                var status = sqlite3_step(statement)
                while status == SQLITE_ROW {
                    let id = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? "unknown"
                    guard let blob = sqlite3_column_blob(statement, 1) else {
                        throw DatabaseError.decodingFailed(
                            collection: collection.rawValue, id: id, message: "missing JSON blob"
                        )
                    }
                    let size = Int(sqlite3_column_bytes(statement, 1))
                    let data = Data(bytes: blob, count: size)
                    do {
                        results.append(try JSONDecoder.palmSync.decode(T.self, from: data))
                    } catch {
                        throw DatabaseError.decodingFailed(
                            collection: collection.rawValue, id: id, message: error.localizedDescription
                        )
                    }
                    status = sqlite3_step(statement)
                }
                guard status == SQLITE_DONE else {
                    throw DatabaseError.statementFailed(String(cString: sqlite3_errmsg(handle)))
                }
            }
            return results
        }
    }

    public func delete(id: String, from collection: Collection) throws {
        try queue.sync {
            try write("DELETE FROM items WHERE collection = ? AND id = ?") { statement in
                sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
                sqlite3_bind_text(statement, 2, id, -1, Self.sqliteTransient)
            }
        }
    }

    public func deleteAll(in collection: Collection) throws {
        try queue.sync {
            try write("DELETE FROM items WHERE collection = ?") { statement in
                sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
            }
        }
    }

    public func count(in collection: Collection) throws -> Int {
        try queue.sync {
            var total = 0
            try query("SELECT COUNT(*) FROM items WHERE collection = ?") { statement in
                sqlite3_bind_text(statement, 1, collection.rawValue, -1, Self.sqliteTransient)
                let status = sqlite3_step(statement)
                if status == SQLITE_ROW {
                    total = Int(sqlite3_column_int64(statement, 0))
                } else if status != SQLITE_DONE {
                    throw DatabaseError.statementFailed(String(cString: sqlite3_errmsg(handle)))
                }
            }
            return total
        }
    }

    // MARK: - SQLite plumbing

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(handle, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errorMessage)
            throw DatabaseError.statementFailed(message)
        }
    }

    private func withStatement(_ sql: String, body: (OpaquePointer?) throws -> Void) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.statementFailed(String(cString: sqlite3_errmsg(handle)))
        }
        defer { sqlite3_finalize(statement) }
        try body(statement)
    }

    private func write(_ sql: String, bind: (OpaquePointer?) throws -> Void) throws {
        try withStatement(sql) { statement in
            try bind(statement)
            guard sqlite3_step(statement) == SQLITE_DONE else {
                throw DatabaseError.statementFailed(String(cString: sqlite3_errmsg(handle)))
            }
        }
    }

    private func query(_ sql: String, body: (OpaquePointer?) throws -> Void) throws {
        try withStatement(sql, body: body)
    }
}

public extension JSONEncoder {
    static var palmSync: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

public extension JSONDecoder {
    static var palmSync: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
