import Foundation
import SwiftData

nonisolated protocol IdentifiableByServerID {
    var serverID: String { get }
    static func predicate(id: String) -> Predicate<Self>
}

extension MuseumEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<MuseumEntity> {
        #Predicate { $0.id == id }
    }
}

extension LanguageEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<LanguageEntity> {
        #Predicate { $0.id == id }
    }
}

extension FloorEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<FloorEntity> {
        #Predicate { $0.id == id }
    }
}

extension RoomEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<RoomEntity> {
        #Predicate { $0.id == id }
    }
}

extension ExhibitionEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<ExhibitionEntity> {
        #Predicate { $0.id == id }
    }
}

extension ExhibitionTranslationEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<ExhibitionTranslationEntity> {
        #Predicate { $0.id == id }
    }
}

extension ArtworkEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<ArtworkEntity> {
        #Predicate { $0.id == id }
    }
}

extension ArtworkTranslationEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<ArtworkTranslationEntity> {
        #Predicate { $0.id == id }
    }
}

extension PageEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<PageEntity> {
        #Predicate { $0.id == id }
    }
}

extension PageTranslationEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<PageTranslationEntity> {
        #Predicate { $0.id == id }
    }
}

extension SyncStateEntity: IdentifiableByServerID {
    var serverID: String { id }

    static func predicate(id: String) -> Predicate<SyncStateEntity> {
        #Predicate { $0.id == id }
    }
}
