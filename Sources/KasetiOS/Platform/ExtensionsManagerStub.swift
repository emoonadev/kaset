import Foundation

/// iOS has no web-extension support in v1 (D4); `WebKitManager` only asks this for an empty list.
@MainActor
final class ExtensionsManager {
    static let shared = ExtensionsManager()

    struct ManagedExtension {
        let id: String
        let optionsPath: String?
        let popupPath: String?
    }

    let extensions: [ManagedExtension] = []

    func resolvedURLs() -> [(id: String, url: URL)] {
        []
    }
}
