import Foundation

// Phase 5/6 surface: the sync engine talks to Google and iCloud only through
// these protocols, so providers can be developed and tested independently.
// GoogleCloudProvider needs an OAuth client ID (PKCE, no embedded secret);
// ICloudProvider should start with EventKit/Contacts before raw Cal/CardDAV.

/// A neutral change-set representation exchanged with cloud providers.
public struct CloudChange<Item: Sendable>: Sendable {
    public var upserted: [Item]
    public var deletedIDs: [String]
    /// Opaque incremental-sync token (Google syncToken, DAV sync-token).
    public var nextCursor: String?

    public init(upserted: [Item] = [], deletedIDs: [String] = [], nextCursor: String? = nil) {
        self.upserted = upserted
        self.deletedIDs = deletedIDs
        self.nextCursor = nextCursor
    }
}

public struct CloudEvent: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var title: String
    public var start: Date
    public var durationMinutes: Int
    public var location: String?

    public init(id: String, title: String, start: Date, durationMinutes: Int, location: String? = nil) {
        self.id = id
        self.title = title
        self.start = start
        self.durationMinutes = durationMinutes
        self.location = location
    }
}

public struct CloudContact: Codable, Identifiable, Sendable, Equatable {
    public var id: String
    public var name: String
    public var organization: String?
    public var phones: [String]
    public var emails: [String]

    public init(id: String, name: String, organization: String? = nil, phones: [String] = [], emails: [String] = []) {
        self.id = id
        self.name = name
        self.organization = organization
        self.phones = phones
        self.emails = emails
    }
}

public enum CloudProviderState: Sendable, Equatable {
    case disconnected
    case needsAuthorization
    case connected(account: String)
}

/// Contract every cloud backend implements. `cursor` enables incremental
/// sync; pass nil for a full fetch.
public protocol CloudProvider: Sendable {
    var providerID: String { get }
    var state: CloudProviderState { get async }

    func authorize() async throws
    func fetchEvents(since cursor: String?) async throws -> CloudChange<CloudEvent>
    func fetchContacts(since cursor: String?) async throws -> CloudChange<CloudContact>
    func push(events: [CloudEvent], deletedIDs: [String]) async throws
    func push(contacts: [CloudContact], deletedIDs: [String]) async throws
}

/// In-memory provider used by tests and by the UI while real providers are
/// being wired up.
public actor InMemoryCloudProvider: CloudProvider {
    public let providerID: String
    private var events: [CloudEvent]
    private var contacts: [CloudContact]
    private var authorized = false

    public init(providerID: String, events: [CloudEvent] = [], contacts: [CloudContact] = []) {
        self.providerID = providerID
        self.events = events
        self.contacts = contacts
    }

    public var state: CloudProviderState {
        authorized ? .connected(account: "demo@\(providerID)") : .needsAuthorization
    }

    public func authorize() async throws { authorized = true }

    public func fetchEvents(since cursor: String?) async throws -> CloudChange<CloudEvent> {
        CloudChange(upserted: events, nextCursor: UUID().uuidString)
    }

    public func fetchContacts(since cursor: String?) async throws -> CloudChange<CloudContact> {
        CloudChange(upserted: contacts, nextCursor: UUID().uuidString)
    }

    public func push(events newEvents: [CloudEvent], deletedIDs: [String]) async throws {
        events.removeAll { deletedIDs.contains($0.id) }
        for event in newEvents {
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = event
            } else {
                events.append(event)
            }
        }
    }

    public func push(contacts newContacts: [CloudContact], deletedIDs: [String]) async throws {
        contacts.removeAll { deletedIDs.contains($0.id) }
        for contact in newContacts {
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = contact
            } else {
                contacts.append(contact)
            }
        }
    }
}
