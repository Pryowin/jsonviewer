import AppKit

/// Receives the "open this file" Apple Event that Finder sends when a user
/// double-clicks a JSON file or uses "Open With" — SwiftUI's `App` protocol
/// has no scene-level hook for this, so it has to be handled here.
///
/// The event can arrive before the SwiftUI scene has built its view (and
/// therefore before `model` is set), so an early URL is buffered in
/// `pendingURL` and flushed once the model becomes available.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: JSONDocumentModel?
    private var pendingURL: URL?

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        if let model {
            model.load(url: url)
        } else {
            pendingURL = url
        }
    }

    func attach(model: JSONDocumentModel) {
        self.model = model
        if let pendingURL {
            model.load(url: pendingURL)
            self.pendingURL = nil
        }
    }
}
