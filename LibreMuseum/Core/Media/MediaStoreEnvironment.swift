import SwiftUI

private struct MediaStoreKey: EnvironmentKey {
    static let defaultValue: MediaStore? = nil
}

extension EnvironmentValues {
    var mediaStore: MediaStore? {
        get { self[MediaStoreKey.self] }
        set { self[MediaStoreKey.self] = newValue }
    }
}
