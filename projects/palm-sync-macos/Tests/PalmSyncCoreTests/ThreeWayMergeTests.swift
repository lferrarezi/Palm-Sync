import Foundation
import Testing
@testable import PalmSyncCore

private struct Note: Syncable {
    var syncID: String
    var text: String
    var isDeleted = false
}

struct ThreeWayMergeTests {
    @Test func noChangesMeansNoConflicts() {
        let items = [Note(syncID: "a", text: "x")]
        let result = ThreeWayMerge.merge(base: items, mine: items, theirs: items)
        #expect(result.merged == items)
        #expect(result.conflicts.isEmpty)
    }

    @Test func oneSidedEditWins() {
        let base = [Note(syncID: "a", text: "old")]
        let mine = [Note(syncID: "a", text: "new")]
        let result = ThreeWayMerge.merge(base: base, mine: mine, theirs: base)
        #expect(result.merged == mine)
        #expect(result.conflicts.isEmpty)
    }

    @Test func additionsFromBothSidesAreKept() {
        let base: [Note] = []
        let mine = [Note(syncID: "a", text: "mine")]
        let theirs = [Note(syncID: "b", text: "theirs")]
        let result = ThreeWayMerge.merge(base: base, mine: mine, theirs: theirs)
        #expect(Set(result.merged.map(\.syncID)) == ["a", "b"])
        #expect(result.conflicts.isEmpty)
    }

    @Test func concurrentDifferentEditsConflict() {
        let base = [Note(syncID: "a", text: "old")]
        let mine = [Note(syncID: "a", text: "mine")]
        let theirs = [Note(syncID: "a", text: "theirs")]
        let result = ThreeWayMerge.merge(base: base, mine: mine, theirs: theirs)
        #expect(result.merged.isEmpty)
        #expect(result.conflicts.count == 1)
        #expect(result.conflicts[0].mine?.text == "mine")
        #expect(result.conflicts[0].theirs?.text == "theirs")
    }

    @Test func identicalConcurrentEditsConverge() {
        let base = [Note(syncID: "a", text: "old")]
        let both = [Note(syncID: "a", text: "same")]
        let result = ThreeWayMerge.merge(base: base, mine: both, theirs: both)
        #expect(result.merged == both)
        #expect(result.conflicts.isEmpty)
    }

    @Test func deletionWithoutConcurrentEditApplies() {
        let base = [Note(syncID: "a", text: "x")]
        let mine = [Note(syncID: "a", text: "x", isDeleted: true)]
        let result = ThreeWayMerge.merge(base: base, mine: mine, theirs: base)
        #expect(result.merged.isEmpty)
        #expect(result.deletedIDs == ["a"])
        #expect(result.conflicts.isEmpty)
    }

    @Test func deleteVersusEditConflicts() {
        let base = [Note(syncID: "a", text: "x")]
        let mine: [Note] = [Note(syncID: "a", text: "x", isDeleted: true)]
        let theirs = [Note(syncID: "a", text: "edited")]
        let result = ThreeWayMerge.merge(base: base, mine: mine, theirs: theirs)
        #expect(result.conflicts.count == 1)
        #expect(result.conflicts[0].mine == nil)
        #expect(result.conflicts[0].theirs?.text == "edited")
    }

    @Test func duplicateIDsAreReportedAndExcluded() {
        let mine = [
            Note(syncID: "a", text: "first"),
            Note(syncID: "a", text: "second")
        ]
        let result = ThreeWayMerge.merge(base: [], mine: mine, theirs: [])
        #expect(result.duplicateIDs == ["a"])
        #expect(result.merged.isEmpty)
    }

    @Test func mergedOrderIsStableAcrossSnapshots() {
        let base = [Note(syncID: "b", text: "b"), Note(syncID: "a", text: "a")]
        let theirs = base + [Note(syncID: "c", text: "c")]
        let result = ThreeWayMerge.merge(base: base, mine: base, theirs: theirs)
        #expect(result.merged.map(\.syncID) == ["b", "a", "c"])
    }
}
