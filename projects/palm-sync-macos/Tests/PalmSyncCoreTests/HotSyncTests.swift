import Foundation
import Testing
@testable import PalmSyncCore

struct HotSyncTests {
    private func userInfoPayload(name: String, userID: UInt32) -> Data {
        var payload = Data()
        payload.append(contentsOf: [
            UInt8((userID >> 24) & 0xFF), UInt8((userID >> 16) & 0xFF),
            UInt8((userID >> 8) & 0xFF), UInt8(userID & 0xFF)
        ])
        payload.append(contentsOf: Array(repeating: 0, count: 24)) // viewer/lastPC/dates
        let nameBytes = Array(name.utf8) + [0]
        payload.append(UInt8(nameBytes.count))
        payload.append(0) // password length
        payload.append(contentsOf: nameBytes)
        return payload
    }

    @Test func readsUserInfoThroughTransport() async throws {
        let transport = MockHotSyncTransport(responses: [userInfoPayload(name: "Luiz", userID: 42)])
        try await transport.open()
        let session = DLPSession(transport: transport)
        let info = try await session.readUserInfo()
        #expect(info.userName == "Luiz")
        #expect(info.userID == 42)

        let frames = await transport.sentFrames
        #expect(frames.first?.first == DLPCommand.readUserInfo.rawValue)
    }

    @Test func closedTransportThrows() async throws {
        let transport = MockHotSyncTransport(responses: [])
        let session = DLPSession(transport: transport)
        await #expect(throws: HotSyncError.transportClosed) {
            _ = try await session.readUserInfo()
        }
    }

    @Test func malformedUserInfoThrows() {
        #expect(throws: HotSyncError.malformedResponse) {
            _ = try DLPSession.parseUserInfo(Data([0x00, 0x01]))
        }
    }

    @Test func oversizedDLPArgumentThrowsInsteadOfTrapping() {
        #expect(throws: HotSyncError.argumentTooLarge) {
            _ = try DLPSession.requestFrame(
                command: .readDBList,
                arguments: [Data(repeating: 0, count: 256)]
            )
        }
    }

    @Test func tooManyDLPArgumentsThrowInsteadOfOverflowingArgumentID() {
        #expect(throws: HotSyncError.argumentTooLarge) {
            _ = try DLPSession.requestFrame(
                command: .readDBList,
                arguments: Array(repeating: Data(), count: 225)
            )
        }
    }

    @Test func cloudProviderRoundTrips() async throws {
        let provider = InMemoryCloudProvider(providerID: "google")
        try await provider.authorize()
        let state = await provider.state
        #expect(state == .connected(account: "demo@google"))

        let contact = CloudContact(id: "c1", name: "Ana", emails: ["ana@example.com"])
        try await provider.push(contacts: [contact], deletedIDs: [])
        let change = try await provider.fetchContacts(since: nil)
        #expect(change.upserted == [contact])
        #expect(change.nextCursor != nil)
    }

    @Test func keychainStoresAndRemovesSecrets() throws {
        let store = KeychainStore(service: "palm-sync-tests-\(UUID().uuidString)")
        let account = "oauth-token"
        let secret = Data("token-123".utf8)

        try store.set(secret, for: account)
        #expect(try store.get(account) == secret)

        try store.set(Data("token-456".utf8), for: account)
        #expect(try store.get(account) == Data("token-456".utf8))

        try store.remove(account)
        #expect(try store.get(account) == nil)
    }
}
