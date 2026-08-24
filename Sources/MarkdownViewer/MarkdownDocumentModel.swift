import Foundation
import SwiftUI

@MainActor
final class MarkdownDocumentModel: ObservableObject {
    @Published var fileURL: URL?
    @Published var renderedText: String = ""

    @Published var isEditing = false
    @Published var editableText: String = ""

    @Published var statusMessage: String?
    @Published var loadError: String?

    func load(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) else {
                loadError = "File is not valid UTF-8 text."
                return
            }
            self.fileURL = url
            self.renderedText = text
            self.editableText = text
            self.loadError = nil
            self.isEditing = false
            self.statusMessage = "Loaded \(url.lastPathComponent)"
        } catch {
            self.loadError = "Could not open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func beginEditing() {
        editableText = renderedText
        isEditing = true
    }

    func cancelEditing() {
        editableText = renderedText
        isEditing = false
    }

    @discardableResult
    func save() -> Bool {
        guard let fileURL else { return false }
        do {
            try editableText.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            self.renderedText = editableText
            self.isEditing = false
            self.statusMessage = "Saved \(fileURL.lastPathComponent)"
            return true
        } catch {
            self.loadError = "Could not save \(fileURL.lastPathComponent): \(error.localizedDescription)"
            return false
        }
    }
}
