import Foundation

nonisolated struct ArtworkUI: Identifiable, Sendable, Hashable {
    let id: String
    let exhibitionID: String
    let code: String
    let title: String
    let searchableTitles: [String]
    let artist: String
    let year: String
    let thumbnailPath: String
    let hasAudioGuide: Bool
    let isLocked: Bool
}

nonisolated struct ArtworkDetailUI: Identifiable, Sendable, Equatable {
    let id: String
    let exhibitionID: String
    let code: String
    let title: String
    let artist: String
    let year: String
    let technique: String
    let inventoryNumber: String
    let roomName: String
    let imagePaths: [String]
    let text: String
    let audioPath: String
    let audioDuration: Int
    let textLanguageCode: String
    let hasTranslation: Bool
    let isLocked: Bool

    var hasAudioGuide: Bool { !audioPath.isEmpty }
    var hasReadAloudGuide: Bool { audioPath.isEmpty && !text.isEmpty }
}
