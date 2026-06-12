import Foundation

/// Helpers shared by the PDB parsers: Palm OS dates and text encoding.
///
/// Palm OS stores dates as seconds since 1904-01-01 (Mac epoch) and packs
/// calendar dates into 16 bits (7 bits year-1904, 4 bits month, 5 bits day).
/// Text is CP1252/Latin-1, never UTF-8.
public enum PalmEncoding {
    /// Seconds between 1904-01-01 and 1970-01-01.
    public static let macEpochOffset: TimeInterval = 2_082_844_800

    public static func date(fromMacSeconds seconds: UInt32) -> Date? {
        guard seconds > 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(seconds) - macEpochOffset)
    }

    /// Unpacks a 16-bit Palm packed date. `0xFFFF` means "no date".
    public static func date(fromPacked packed: UInt16) -> Date? {
        guard packed != 0xFFFF, packed != 0 else { return nil }
        let year = Int((packed >> 9) & 0x7F) + 1904
        let month = Int((packed >> 5) & 0x0F)
        let day = Int(packed & 0x1F)
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar.date(from: components)
    }

    public static func packedDate(from date: Date) -> UInt16 {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let clampedYear = min(2031, max(1904, components.year ?? 1904))
        let year = UInt16(clampedYear - 1904)
        let month = UInt16(components.month ?? 1) & 0x0F
        let day = UInt16(components.day ?? 1) & 0x1F
        return (year << 9) | (month << 5) | day
    }

    public static func string(from bytes: some Sequence<UInt8>) -> String {
        let data = Data(bytes)
        return String(data: data, encoding: .windowsCP1252)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(decoding: data, as: UTF8.self)
    }

    /// Reads a NUL-terminated CP1252 string starting at `offset`, advancing it
    /// past the terminator.
    public static func cString(in data: Data, offset: inout Int) -> String {
        guard offset >= 0, offset < data.count else {
            offset = data.count
            return ""
        }
        let start = offset
        while offset < data.count, data[data.startIndex + offset] != 0 {
            offset += 1
        }
        let slice = data[(data.startIndex + start)..<(data.startIndex + offset)]
        if offset < data.count { offset += 1 }
        return string(from: slice)
    }
}

extension Data {
    func readUInt16(at offset: Int) -> UInt16? {
        guard offset + 2 <= count else { return nil }
        let base = startIndex + offset
        return UInt16(self[base]) << 8 | UInt16(self[base + 1])
    }

    func readUInt32(at offset: Int) -> UInt32? {
        guard offset + 4 <= count else { return nil }
        let base = startIndex + offset
        return UInt32(self[base]) << 24
            | UInt32(self[base + 1]) << 16
            | UInt32(self[base + 2]) << 8
            | UInt32(self[base + 3])
    }
}
