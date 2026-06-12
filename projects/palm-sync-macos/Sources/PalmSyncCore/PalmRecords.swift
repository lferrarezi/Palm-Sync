import Foundation

// Decoders for the four classic Palm OS PIM databases. Record layouts follow
// the formats documented for Palm OS 3–5 (same ones pilot-link implements).
// Verified against synthetic fixtures; flagged fields should be re-validated
// with real LifeDrive/Zire 22 backups before enabling Palm writes.

/// AddressDB: 4 bytes phone-label flags, 4 bytes field bitmap, 1 byte company
/// offset, then one NUL-terminated CP1252 string per bit set in the bitmap.
public struct PalmAddressRecord: Sendable, Equatable {
    public var lastName: String?
    public var firstName: String?
    public var company: String?
    public var phones: [String]
    public var address: String?
    public var city: String?
    public var state: String?
    public var zip: String?
    public var country: String?
    public var title: String?
    public var customFields: [String]
    public var note: String?

    public var displayName: String {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        if !name.isEmpty { return name }
        return company ?? "—"
    }

    public init?(recordData data: Data) {
        guard data.count > 9 else { return nil }
        guard let fieldMap = data.readUInt32(at: 4) else { return nil }

        var offset = 9
        var fields: [Int: String] = [:]
        for bit in 0..<19 where fieldMap & (1 << bit) != 0 {
            guard offset < data.count else { break }
            fields[bit] = PalmEncoding.cString(in: data, offset: &offset)
        }

        lastName = fields[0]
        firstName = fields[1]
        company = fields[2]
        phones = (3...7).compactMap { fields[$0] }
        address = fields[8]
        city = fields[9]
        state = fields[10]
        zip = fields[11]
        country = fields[12]
        title = fields[13]
        customFields = (14...17).compactMap { fields[$0] }
        note = fields[18]
    }
}

/// MemoDB: the record is a single NUL-terminated CP1252 string. The first
/// line is conventionally the title.
public struct PalmMemoRecord: Sendable, Equatable {
    public var text: String

    public var title: String {
        text.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? text
    }

    public var body: String {
        let parts = text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        return parts.count > 1 ? String(parts[1]) : ""
    }

    public init?(recordData data: Data) {
        guard !data.isEmpty else { return nil }
        var offset = 0
        text = PalmEncoding.cString(in: data, offset: &offset)
        if text.isEmpty { return nil }
    }
}

/// ToDoDB: 2 bytes packed due date (0xFFFF = none), 1 byte priority with the
/// high bit meaning "completed", then description and note as C strings.
public struct PalmTodoRecord: Sendable, Equatable {
    public var dueDate: Date?
    public var priority: Int
    public var isCompleted: Bool
    public var description: String
    public var note: String?

    public init?(recordData data: Data) {
        guard data.count > 3, let packedDate = data.readUInt16(at: 0) else { return nil }
        dueDate = PalmEncoding.date(fromPacked: packedDate)
        let priorityByte = data[data.startIndex + 2]
        isCompleted = priorityByte & 0x80 != 0
        priority = Int(priorityByte & 0x7F)
        var offset = 3
        description = PalmEncoding.cString(in: data, offset: &offset)
        let noteText = PalmEncoding.cString(in: data, offset: &offset)
        note = noteText.isEmpty ? nil : noteText
    }
}

/// DatebookDB: start hour/min, end hour/min (0xFF = untimed), 2 bytes packed
/// date, 1 byte flags + 1 pad, then optional blocks (alarm 2B, repeat 8B,
/// exceptions 2B count + 2B each) followed by description and note C strings.
public struct PalmDatebookRecord: Sendable, Equatable {
    public var date: Date?
    public var startHour: Int?
    public var startMinute: Int?
    public var endHour: Int?
    public var endMinute: Int?
    public var description: String
    public var note: String?
    public var hasAlarm: Bool
    public var repeats: Bool

    private static let flagAlarm: UInt8 = 0x40
    private static let flagRepeat: UInt8 = 0x20
    private static let flagNote: UInt8 = 0x10
    private static let flagExceptions: UInt8 = 0x08
    private static let flagDescription: UInt8 = 0x04

    public var startDate: Date? {
        guard let date else { return nil }
        guard let startHour, let startMinute else { return date }
        return Calendar(identifier: .gregorian).date(
            bySettingHour: startHour, minute: startMinute, second: 0, of: date
        )
    }

    public var durationMinutes: Int {
        guard let startHour, let startMinute, let endHour, let endMinute else { return 0 }
        return max(0, (endHour * 60 + endMinute) - (startHour * 60 + startMinute))
    }

    public init?(recordData data: Data) {
        guard data.count >= 8, let packedDate = data.readUInt16(at: 4) else { return nil }

        let rawStartHour = data[data.startIndex]
        let rawStartMinute = data[data.startIndex + 1]
        let rawEndHour = data[data.startIndex + 2]
        let rawEndMinute = data[data.startIndex + 3]
        let untimed = rawStartHour == 0xFF && rawStartMinute == 0xFF

        startHour = untimed ? nil : Int(rawStartHour)
        startMinute = untimed ? nil : Int(rawStartMinute)
        endHour = untimed ? nil : Int(rawEndHour)
        endMinute = untimed ? nil : Int(rawEndMinute)
        if !untimed {
            guard rawStartHour < 24, rawEndHour < 24, rawStartMinute < 60, rawEndMinute < 60 else {
                return nil
            }
        }
        date = PalmEncoding.date(fromPacked: packedDate)

        let flags = data[data.startIndex + 6]
        hasAlarm = flags & Self.flagAlarm != 0
        repeats = flags & Self.flagRepeat != 0

        var offset = 8
        if hasAlarm {
            guard offset + 2 <= data.count else { return nil }
            offset += 2
        }
        if repeats {
            guard offset + 8 <= data.count else { return nil }
            offset += 8
        }
        if flags & Self.flagExceptions != 0 {
            guard let rawCount = data.readUInt16(at: offset) else { return nil }
            let count = Int(rawCount)
            guard offset + 2 + count * 2 <= data.count else { return nil }
            offset += 2 + count * 2
        }

        if flags & Self.flagDescription != 0, offset < data.count {
            description = PalmEncoding.cString(in: data, offset: &offset)
        } else {
            description = ""
        }
        if flags & Self.flagNote != 0, offset < data.count {
            let text = PalmEncoding.cString(in: data, offset: &offset)
            note = text.isEmpty ? nil : text
        } else {
            note = nil
        }
        if description.isEmpty && note == nil { return nil }
    }
}

/// Typed view over a parsed PDB file.
public struct PalmDecodedRecord<Value: Sendable>: Sendable {
    public let uniqueID: UInt32
    public let value: Value
    public let category: String?

    public init(uniqueID: UInt32, value: Value, category: String? = nil) {
        self.uniqueID = uniqueID
        self.value = value
        self.category = category
    }
}

public enum PalmDatabaseContent: Sendable {
    case addresses([PalmDecodedRecord<PalmAddressRecord>])
    case memos([PalmDecodedRecord<PalmMemoRecord>])
    case todos([PalmDecodedRecord<PalmTodoRecord>])
    case datebook([PalmDecodedRecord<PalmDatebookRecord>])
    case unknown(name: String, recordCount: Int)

    public init(file: PDBFile) {
        let live = file.records.filter { !$0.isDeleted }
        switch file.kind {
        case .address:
            self = .addresses(live.compactMap { record in
                PalmAddressRecord(recordData: record.data).map {
                    PalmDecodedRecord(uniqueID: record.uniqueID, value: $0)
                }
            })
        case .memo:
            self = .memos(live.compactMap { record in
                PalmMemoRecord(recordData: record.data).map {
                    PalmDecodedRecord(
                        uniqueID: record.uniqueID,
                        value: $0,
                        category: file.categoryName(for: record)
                    )
                }
            })
        case .todo:
            self = .todos(live.compactMap { record in
                PalmTodoRecord(recordData: record.data).map {
                    PalmDecodedRecord(uniqueID: record.uniqueID, value: $0)
                }
            })
        case .datebook:
            self = .datebook(live.compactMap { record in
                PalmDatebookRecord(recordData: record.data).map {
                    PalmDecodedRecord(uniqueID: record.uniqueID, value: $0)
                }
            })
        case .unknown:
            self = .unknown(name: file.name, recordCount: live.count)
        }
    }
}
