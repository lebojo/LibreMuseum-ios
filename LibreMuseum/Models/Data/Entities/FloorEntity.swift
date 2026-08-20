import Foundation
import SwiftData

@Model
final class FloorEntity {
    @Attribute(.unique) var id: String
    var name: String
    var level: Int
    var mapPath: String
    var sort: Int
    var fetchedVersion: String

    init(
        id: String,
        name: String = "",
        level: Int = 0,
        mapPath: String = "",
        sort: Int = 0,
        fetchedVersion: String = ""
    ) {
        self.id = id
        self.name = name
        self.level = level
        self.mapPath = mapPath
        self.sort = sort
        self.fetchedVersion = fetchedVersion
    }
}
