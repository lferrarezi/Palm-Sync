import Foundation
import Testing
@testable import PalmSyncCore

/// Builds a minimal valid PDB byte stream for tests.
private func makePDB(name: String, type: String, creator: String, records: [Data]) -> Data {
    var data = Data()
    var nameBytes = Array(name.utf8.prefix(31))
    nameBytes.append(contentsOf: Array(repeating: 0, count: 32 - nameBytes.count))
    data.append(contentsOf: nameBytes)
    data.append(contentsOf: [0, 0])                  // attributes
    data.append(contentsOf: [0, 1])                  // version
    data.append(contentsOf: Array(repeating: 0, count: 12)) // creation/mod/backup dates
    data.append(contentsOf: Array(repeating: 0, count: 4))  // modnum
    data.append(contentsOf: Array(repeating: 0, count: 8))  // appInfo + sortInfo offsets
    data.append(contentsOf: Array(type.utf8))
    data.append(contentsOf: Array(creator.utf8))
    data.append(contentsOf: Array(repeating: 0, count: 8))  // uniqueID seed + nextRecordList
    data.append(contentsOf: [0, UInt8(records.count)])      // record count

    let headerEnd = 78 + records.count * 8
    var offset = headerEnd
    for (index, record) in records.enumerated() {
        data.append(contentsOf: [
            UInt8((offset >> 24) & 0xFF), UInt8((offset >> 16) & 0xFF),
            UInt8((offset >> 8) & 0xFF), UInt8(offset & 0xFF)
        ])
        data.append(0)                                // record attributes
        data.append(contentsOf: [0, 0, UInt8(index + 1)]) // uniqueID
        offset += record.count
    }
    for record in records { data.append(record) }
    return data
}

private func cString(_ text: String) -> Data {
    var data = Data(text.unicodeScalars.map { UInt8($0.value & 0xFF) })
    data.append(0)
    return data
}

struct PDBFileTests {
    @Test func parsesHeaderAndRecords() throws {
        let pdb = makePDB(name: "MemoDB", type: "DATA", creator: "memo", records: [
            cString("Primeira nota\nCorpo da nota"),
            cString("Segunda nota")
        ])
        let file = try PDBFile(data: pdb)
        #expect(file.name == "MemoDB")
        #expect(file.creator == "memo")
        #expect(file.kind == .memo)
        #expect(file.records.count == 2)
    }

    @Test func rejectsTruncatedHeader() {
        #expect(throws: PDBFile.ParseError.truncatedHeader) {
            _ = try PDBFile(data: Data(repeating: 0, count: 10))
        }
    }

    @Test func rejectsRecordOffsetInsideHeader() {
        var pdb = makePDB(name: "MemoDB", type: "DATA", creator: "memo", records: [cString("x")])
        pdb.replaceSubrange(78..<82, with: [0, 0, 0, 1])
        #expect(throws: PDBFile.ParseError.recordOutOfBounds(index: 0)) {
            _ = try PDBFile(data: pdb)
        }
    }

    @Test func rejectsResourceDatabase() {
        var pdb = makePDB(name: "Resource", type: "appl", creator: "test", records: [])
        pdb.replaceSubrange(32..<34, with: [0, 1])
        #expect(throws: PDBFile.ParseError.unsupportedResourceDatabase) {
            _ = try PDBFile(data: pdb)
        }
    }

    @Test func decodesMemoRecords() throws {
        let pdb = makePDB(name: "MemoDB", type: "DATA", creator: "memo", records: [
            cString("Título\nCorpo do memo")
        ])
        let file = try PDBFile(data: pdb)
        guard case let .memos(memos) = PalmDatabaseContent(file: file) else {
            Issue.record("Expected memo content")
            return
        }
        #expect(memos.count == 1)
        #expect(memos[0].value.title == "Título")
        #expect(memos[0].value.body == "Corpo do memo")
    }

    @Test func decodesTodoRecords() throws {
        var record = Data()
        record.append(contentsOf: [0xFF, 0xFF])      // no due date
        record.append(0x82)                          // completed, priority 2
        record.append(cString("Comprar cabo USB"))
        record.append(cString(""))                   // empty note

        let pdb = makePDB(name: "ToDoDB", type: "DATA", creator: "todo", records: [record])
        let file = try PDBFile(data: pdb)
        guard case let .todos(todos) = PalmDatabaseContent(file: file) else {
            Issue.record("Expected todo content")
            return
        }
        #expect(todos.count == 1)
        #expect(todos[0].value.isCompleted)
        #expect(todos[0].value.priority == 2)
        #expect(todos[0].value.dueDate == nil)
        #expect(todos[0].value.description == "Comprar cabo USB")
    }

    @Test func decodesAddressRecords() throws {
        var record = Data()
        record.append(contentsOf: [0, 0, 0, 0])      // phone label flags
        // Field bitmap: lastName(0), firstName(1), company(2), phone1(3)
        record.append(contentsOf: [0x00, 0x00, 0x00, 0b0000_1111])
        record.append(0)                              // company offset
        record.append(cString("Pereira"))
        record.append(cString("Ana"))
        record.append(cString("Casa"))
        record.append(cString("+55 11 99999-0101"))

        let pdb = makePDB(name: "AddressDB", type: "DATA", creator: "addr", records: [record])
        let file = try PDBFile(data: pdb)
        guard case let .addresses(addresses) = PalmDatabaseContent(file: file) else {
            Issue.record("Expected address content")
            return
        }
        #expect(addresses.count == 1)
        #expect(addresses[0].value.displayName == "Ana Pereira")
        #expect(addresses[0].value.company == "Casa")
        #expect(addresses[0].value.phones == ["+55 11 99999-0101"])
    }

    @Test func decodesDatebookRecords() throws {
        var record = Data()
        record.append(contentsOf: [9, 30, 10, 15])    // 09:30–10:15
        let packed = PalmEncoding.packedDate(from: Date(timeIntervalSince1970: 1_750_000_000))
        record.append(contentsOf: [UInt8(packed >> 8), UInt8(packed & 0xFF)])
        record.append(0x04)                           // flags: description only
        record.append(0)                              // padding
        record.append(cString("Consulta médica"))

        let pdb = makePDB(name: "DatebookDB", type: "DATA", creator: "date", records: [record])
        let file = try PDBFile(data: pdb)
        guard case let .datebook(entries) = PalmDatabaseContent(file: file) else {
            Issue.record("Expected datebook content")
            return
        }
        #expect(entries.count == 1)
        #expect(entries[0].value.description == "Consulta médica")
        #expect(entries[0].value.durationMinutes == 45)
        #expect(entries[0].value.startHour == 9)
    }

    @Test func packedDateRoundTrips() {
        let calendar = Calendar(identifier: .gregorian)
        let original = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11))!
        let unpacked = PalmEncoding.date(fromPacked: PalmEncoding.packedDate(from: original))
        #expect(unpacked == original)
    }

    @Test func invalidPackedDateReturnsNil() {
        let invalidMonth = UInt16((2026 - 1904) << 9) | UInt16(13 << 5) | 1
        #expect(PalmEncoding.date(fromPacked: invalidMonth) == nil)
    }

    @Test func identifiesDatabaseKindByNameFallback() {
        #expect(PalmDatabaseKind(name: "Backup AddressDB", type: "????", creator: "????") == .address)
        #expect(PalmDatabaseKind(name: "stuff", type: "????", creator: "????") == .unknown)
    }
}
