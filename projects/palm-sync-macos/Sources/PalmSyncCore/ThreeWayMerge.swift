import Foundation

/// An item the sync engine can reason about: stable identity, a comparable
/// payload, and tombstone support.
public protocol Syncable: Equatable, Sendable {
    associatedtype ID: Hashable & Sendable
    var syncID: ID { get }
    var isDeleted: Bool { get }
}

/// Result of merging one replica pair against a common base snapshot.
public struct MergeResult<Item: Syncable>: Sendable {
    /// Final state to write to both replicas.
    public var merged: [Item]
    /// Items changed on both sides since the base; require user review.
    public var conflicts: [MergeConflict<Item>]
    /// IDs deleted on at least one side and not edited on the other.
    public var deletedIDs: Set<Item.ID>
    /// Invalid duplicate identities found inside one or more input snapshots.
    /// These records are excluded from the merge instead of crashing or being
    /// selected arbitrarily.
    public var duplicateIDs: Set<Item.ID>
}

public struct MergeConflict<Item: Syncable>: Sendable {
    public var base: Item?
    public var mine: Item?
    public var theirs: Item?

    public enum Resolution: Sendable { case keepMine, keepTheirs }
}

/// Classic three-way merge over snapshots: `base` is the state after the last
/// successful sync, `mine`/`theirs` the two replicas now. Per the project's
/// conflict policy, nothing is overwritten silently — concurrent edits to the
/// same record become conflicts.
public enum ThreeWayMerge {
    public static func merge<Item: Syncable>(
        base: [Item],
        mine: [Item],
        theirs: [Item]
    ) -> MergeResult<Item> {
        let baseIndex = indexed(base)
        let mineIndex = indexed(mine)
        let theirsIndex = indexed(theirs)
        let baseByID = baseIndex.items
        let mineByID = mineIndex.items
        let theirsByID = theirsIndex.items
        let duplicateIDs = baseIndex.duplicates.union(mineIndex.duplicates).union(theirsIndex.duplicates)

        var merged: [Item] = []
        var conflicts: [MergeConflict<Item>] = []
        var deletedIDs: Set<Item.ID> = []

        var allIDs: [Item.ID] = []
        var seen: Set<Item.ID> = []
        for item in base + mine + theirs where seen.insert(item.syncID).inserted {
            allIDs.append(item.syncID)
        }

        for id in allIDs where !duplicateIDs.contains(id) {
            let baseItem = baseByID[id]
            let mineItem = mineByID[id].flatMap { $0.isDeleted ? nil : $0 }
            let theirsItem = theirsByID[id].flatMap { $0.isDeleted ? nil : $0 }

            let mineChanged = changed(base: baseItem, current: mineItem)
            let theirsChanged = changed(base: baseItem, current: theirsItem)

            switch (mineChanged, theirsChanged) {
            case (false, false):
                if let item = mineItem ?? theirsItem { merged.append(item) }
            case (true, false):
                if let mineItem { merged.append(mineItem) } else { deletedIDs.insert(id) }
            case (false, true):
                if let theirsItem { merged.append(theirsItem) } else { deletedIDs.insert(id) }
            case (true, true):
                if mineItem == theirsItem {
                    // Both sides converged on the same value (or both deleted).
                    if let item = mineItem { merged.append(item) } else { deletedIDs.insert(id) }
                } else {
                    conflicts.append(MergeConflict(base: baseItem, mine: mineItem, theirs: theirsItem))
                }
            }
        }

        return MergeResult(
            merged: merged,
            conflicts: conflicts,
            deletedIDs: deletedIDs,
            duplicateIDs: duplicateIDs
        )
    }

    private static func changed<Item: Syncable>(base: Item?, current: Item?) -> Bool {
        switch (base, current) {
        case (nil, nil): false
        case (nil, .some): true
        case (.some, nil): true
        case let (.some(base), .some(current)): base != current
        }
    }

    private static func indexed<Item: Syncable>(_ items: [Item]) -> (items: [Item.ID: Item], duplicates: Set<Item.ID>) {
        var indexed: [Item.ID: Item] = [:]
        var duplicates: Set<Item.ID> = []
        for item in items {
            if indexed.updateValue(item, forKey: item.syncID) != nil {
                duplicates.insert(item.syncID)
            }
        }
        return (indexed, duplicates)
    }
}
