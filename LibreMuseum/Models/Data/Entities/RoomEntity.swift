import Foundation
import SwiftData

@Model
final class RoomEntity {
    @Attribute(.unique) var id: String
    var floorID: String
    var name: String
    var code: String
    var sort: Int
    var fetchedVersion: String

    init(
        id: String,
        floorID: String = "",
        name: String = "",
        code: String = "",
        sort: Int = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.floorID = floorID
        self.name = name
        self.code = code
        self.sort = sort
        self.fetchedVersion = fetchedVersion
    }
}
