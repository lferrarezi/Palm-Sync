import Foundation

// Phase 3 surface: the DLP (Desktop Link Protocol) session is written against
// an abstract transport so the protocol layer can be developed and tested
// before the USB transport (IOUSBHost) lands. Wire format references:
// Palm OS DLP 1.x as implemented by pilot-link (protocol reference only).

/// Byte-level link to a Palm device (USB bulk pipe or serial SLP/PADP).
public protocol HotSyncTransport: Sendable {
    func open() async throws
    func close() async
    func send(_ data: Data) async throws
    func receive(maxLength: Int) async throws -> Data
}

public enum HotSyncError: Error, LocalizedError, Equatable {
    case transportClosed
    case malformedResponse
    case dlpError(code: UInt16)
    case argumentTooLarge

    public var errorDescription: String? {
        switch self {
        case .transportClosed: "HotSync transport is not open"
        case .malformedResponse: "Malformed DLP response"
        case let .dlpError(code): "DLP error 0x\(String(code, radix: 16))"
        case .argumentTooLarge: "DLP request has too many or oversized arguments"
        }
    }
}

/// DLP function IDs needed for the read-only milestones (3a/3b).
public enum DLPCommand: UInt8, Sendable {
    case readUserInfo = 0x10
    case readSysInfo = 0x12
    case readDBList = 0x16
    case openDB = 0x17
    case closeDB = 0x19
    case readRecordByIndex = 0x20
    case endOfSync = 0x2F
}

public struct PalmUserInfo: Sendable, Equatable {
    public var userName: String
    public var userID: UInt32
    public var lastSyncDate: Date?

    public init(userName: String, userID: UInt32, lastSyncDate: Date? = nil) {
        self.userName = userName
        self.userID = userID
        self.lastSyncDate = lastSyncDate
    }
}

/// Protocol-level session. Milestone 3a is `readUserInfo`; 3b iterates
/// `readDBList` + `readRecord` into PDB snapshots for the Phase 2 parsers.
public struct DLPSession: Sendable {
    let transport: any HotSyncTransport

    public init(transport: any HotSyncTransport) {
        self.transport = transport
    }

    /// Builds a DLP request frame: function ID, arg count, then typed args.
    static func requestFrame(command: DLPCommand, arguments: [Data] = []) throws -> Data {
        let maximumSmallArguments = Int(UInt8.max) - 0x20 + 1
        guard arguments.count <= maximumSmallArguments,
              arguments.allSatisfy({ $0.count <= Int(UInt8.max) }) else {
            throw HotSyncError.argumentTooLarge
        }
        var frame = Data([command.rawValue, UInt8(arguments.count)])
        for (index, argument) in arguments.enumerated() {
            // Small-arg encoding: ID (0x20 + index), 1-byte length.
            frame.append(UInt8(0x20 + index))
            frame.append(UInt8(argument.count))
            frame.append(argument)
        }
        return frame
    }

    public func readUserInfo() async throws -> PalmUserInfo {
        try await transport.send(Self.requestFrame(command: .readUserInfo))
        let response = try await transport.receive(maxLength: 512)
        return try Self.parseUserInfo(response)
    }

    public func endSync() async throws {
        try await transport.send(Self.requestFrame(command: .endOfSync, arguments: [Data([0x00, 0x00])]))
        _ = try? await transport.receive(maxLength: 64)
        await transport.close()
    }

    /// DLP ReadUserInfo response payload: userID(4), viewerID(4), lastSyncPC(4),
    /// succSyncDate(8), lastSyncDate(8), userNameLen(1), passwordLen(1), name.
    static func parseUserInfo(_ payload: Data) throws -> PalmUserInfo {
        guard payload.count >= 30 else { throw HotSyncError.malformedResponse }
        let userID = payload.readUInt32(at: 0) ?? 0
        let nameLength = Int(payload[payload.startIndex + 28])
        guard payload.count >= 30 + nameLength else { throw HotSyncError.malformedResponse }
        let nameBytes = payload[(payload.startIndex + 30)..<(payload.startIndex + 30 + nameLength)]
        let name = PalmEncoding.string(from: nameBytes.prefix { $0 != 0 })
        return PalmUserInfo(userName: name, userID: userID)
    }
}

/// Scripted transport for protocol tests and UI demos without hardware.
public actor MockHotSyncTransport: HotSyncTransport {
    private var isOpen = false
    private var responses: [Data]
    public private(set) var sentFrames: [Data] = []

    public init(responses: [Data]) {
        self.responses = responses
    }

    public func open() async throws { isOpen = true }
    public func close() async { isOpen = false }

    public func send(_ data: Data) async throws {
        guard isOpen else { throw HotSyncError.transportClosed }
        sentFrames.append(data)
    }

    public func receive(maxLength: Int) async throws -> Data {
        guard isOpen else { throw HotSyncError.transportClosed }
        guard !responses.isEmpty else { throw HotSyncError.malformedResponse }
        return responses.removeFirst()
    }
}
