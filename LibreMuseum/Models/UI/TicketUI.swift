import Foundation

nonisolated struct LockedExhibitionUI: Identifiable, Sendable, Hashable {
    let id: String
    let title: String
    let unlockCode: String
}

// What the whole interface asks before showing an artwork. Built once per
// screen from the exhibitions and the scanned tickets, then carried into the
// `*UI` models, so that no subview ever has to reach for the ticket store.
nonisolated struct TicketAccess: Sendable, Equatable {
    static let nothingLocked = TicketAccess(lockedByExhibitionID: [:])

    private let lockedByExhibitionID: [String: LockedExhibitionUI]

    init(lockedByExhibitionID: [String: LockedExhibitionUI]) {
        self.lockedByExhibitionID = lockedByExhibitionID
    }

    func isLocked(exhibitionID: String) -> Bool {
        lockedByExhibitionID[exhibitionID] != nil
    }

    func lockedExhibition(id: String) -> LockedExhibitionUI? {
        lockedByExhibitionID[id]
    }
}
