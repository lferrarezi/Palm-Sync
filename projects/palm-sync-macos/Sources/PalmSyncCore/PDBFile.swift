import Foundation

/// A parsed Palm OS database (.pdb) file: 78-byte header, record entry list,
/// optional app info block (categories), and raw record payloads.
public struct PDBFile: Sendable {
    public struct Record: Sendable {
        public let uniqueID: UInt32
        public let attributes: UInt8
        public let categoryIndex: Int
        public let data: Data

        public var isDeleted: Bool { attributes & 0x80 != 0 }
        public var isDirty: Bool { attributes & 0x40 != 0 }
        public var isSecret: Bool { attributes & 0x10 != 0 }
    }

    public let name: String
    public let type: String
    public let creator: String
    public let creationDate: Date?
    public let modificationDate: Date?
    public let categories: [String]
    public let records: [Record]

    public var kind: PalmDatabaseKind { PalmDatabaseKind(name: name, type: type, creator: creator) }

    public enum ParseError: Error, LocalizedError, Equatable {
        case truncatedHeader
        case truncatedRecordList
        case recordOutOfBounds(index: Int)
        case unsupportedResourceDatabase

        public var errorDescription: String? {
            switch self {
            case .truncatedHeader: "PDB header is truncated"
            case .truncatedRecordList: "PDB record list is truncated"
            case let .recordOutOfBounds(index): "PDB record \(index) points outside the file"
            case .unsupportedResourceDatabase: "Resource databases (PRC) are not supported"
            }
        }
    }

    public init(data: Data) throws {
        let headerSize = 78
        guard data.count >= headerSize else { throw ParseError.truncatedHeader }

        name = PalmEncoding.string(from: data.prefix(32).prefix { $0 != 0 })
        let attributes = data.readUInt16(at: 32) ?? 0
        guard attributes & 0x0001 == 0 else { throw ParseError.unsupportedResourceDatabase }
        creationDate = PalmEncoding.date(fromMacSeconds: data.readUInt32(at: 36) ?? 0)
        modificationDate = PalmEncoding.date(fromMacSeconds: data.readUInt32(at: 40) ?? 0)
        let appInfoOffset = Int(data.readUInt32(at: 52) ?? 0)
        type = PalmEncoding.string(from: data.dropFirst(60).prefix(4))
        creator = PalmEncoding.string(from: data.dropFirst(64).prefix(4))
        let recordCount = Int(data.readUInt16(at: 76) ?? 0)

        let listSize = recordCount * 8
        guard data.count >= headerSize + listSize else { throw ParseError.truncatedRecordList }
        let minimumRecordOffset = headerSize + listSize

        struct Entry {
            let offset: Int
            let attributes: UInt8
            let uniqueID: UInt32
        }

        var entries: [Entry] = []
        entries.reserveCapacity(recordCount)
        for index in 0..<recordCount {
            let base = headerSize + index * 8
            let offset = Int(data.readUInt32(at: base) ?? 0)
            let attributes = data[data.startIndex + base + 4]
            let uniqueID = UInt32(data[data.startIndex + base + 5]) << 16
                | UInt32(data[data.startIndex + base + 6]) << 8
                | UInt32(data[data.startIndex + base + 7])
            entries.append(Entry(offset: offset, attributes: attributes, uniqueID: uniqueID))
        }

        categories = Self.parseCategories(data: data, appInfoOffset: appInfoOffset, firstRecordOffset: entries.first?.offset)

        var parsed: [Record] = []
        parsed.reserveCapacity(recordCount)
        for (index, entry) in entries.enumerated() {
            guard entry.offset >= minimumRecordOffset, entry.offset <= data.count else {
                throw ParseError.recordOutOfBounds(index: index)
            }
            let end = index + 1 < entries.count ? entries[index + 1].offset : data.count
            guard end >= entry.offset, end <= data.count else {
                throw ParseError.recordOutOfBounds(index: index)
            }
            let payload = data.subdata(in: (data.startIndex + entry.offset)..<(data.startIndex + end))
            parsed.append(
                Record(
                    uniqueID: entry.uniqueID,
                    attributes: entry.attributes,
                    categoryIndex: Int(entry.attributes & 0x0F),
                    data: payload
                )
            )
        }
        records = parsed
    }

    public func categoryName(for record: Record) -> String? {
        guard categories.indices.contains(record.categoryIndex) else { return nil }
        let name = categories[record.categoryIndex]
        return name.isEmpty ? nil : name
    }

    /// Standard Palm app info block: 2-byte renamed flags then 16 × 16-byte
    /// NUL-padded category names.
    private static func parseCategories(data: Data, appInfoOffset: Int, firstRecordOffset: Int?) -> [String] {
        guard appInfoOffset > 0 else { return [] }
        let end = firstRecordOffset ?? data.count
        guard appInfoOffset + 2 + 16 * 16 <= end, appInfoOffset + 2 + 16 * 16 <= data.count else { return [] }
        var names: [String] = []
        for slot in 0..<16 {
            let start = data.startIndex + appInfoOffset + 2 + slot * 16
            let chunk = data[start..<(start + 16)].prefix { $0 != 0 }
            names.append(PalmEncoding.string(from: chunk))
        }
        return names
    }
}

/// Identifies which classic Palm database a PDB file is, by creator/type with
/// a name-based fallback for renamed files.
public enum PalmDatabaseKind: String, Sendable {
    case address
    case datebook
    case todo
    case memo
    case unknown

    public init(name: String, type: String, creator: String) {
        switch (creator, type) {
        case ("addr", "DATA"): self = .address
        case ("date", "DATA"): self = .datebook
        case ("todo", "DATA"): self = .todo
        case ("memo", "DATA"): self = .memo
        default:
            let lowered = name.lowercased()
            if lowered.contains("address") { self = .address }
            else if lowered.contains("datebook") || lowered.contains("calendar") { self = .datebook }
            else if lowered.contains("todo") || lowered.contains("to do") { self = .todo }
            else if lowered.contains("memo") { self = .memo }
            else { self = .unknown }
        }
    }
}
