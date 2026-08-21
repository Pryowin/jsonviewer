import Foundation
import SwiftUI

@MainActor
final class JSONDocumentModel: ObservableObject {
    @Published var fileURL: URL?
    @Published var rootValue: JSONValue?
    @Published var rootItems: [JSONTreeItem] = []

    @Published var isEditing = false
    @Published var editableText: String = ""
    @Published var validationError: String?

    @Published var statusMessage: String?
    @Published var loadError: String?

    var isValidJSON: Bool { validationError == nil }
    var hasUnsavedChanges = false

    func load(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let text = String(data: data, encoding: .utf8) else {
                loadError = "File is not valid UTF-8 text."
                return
            }
            let value = try JSONParser.parse(text)
            self.fileURL = url
            self.rootValue = value
            self.rootItems = JSONTreeItem.rootItems(from: value)
            self.editableText = value.prettyPrinted()
            self.validationError = nil
            self.loadError = nil
            self.isEditing = false
            self.hasUnsavedChanges = false
            self.statusMessage = "Loaded \(url.lastPathComponent)"
        } catch let error as JSONParseError {
            self.loadError = "Could not parse \(url.lastPathComponent): \(error.localizedDescription)"
        } catch {
            self.loadError = "Could not open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func beginEditing() {
        guard let rootValue else { return }
        editableText = rootValue.prettyPrinted()
        validationError = nil
        isEditing = true
    }

    func cancelEditing() {
        isEditing = false
        validationError = nil
        if let rootValue {
            editableText = rootValue.prettyPrinted()
        }
    }

    /// Re-validates the current editable text; called on every text change.
    func validate() {
        do {
            _ = try JSONParser.parse(editableText)
            validationError = nil
        } catch let error as JSONParseError {
            validationError = error.localizedDescription
        } catch {
            validationError = error.localizedDescription
        }
    }

    @discardableResult
    func save() -> Bool {
        guard let fileURL else { return false }
        do {
            let parsed = try JSONParser.parse(editableText)
            try editableText.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            self.rootValue = parsed
            self.rootItems = JSONTreeItem.rootItems(from: parsed)
            self.editableText = parsed.prettyPrinted()
            self.validationError = nil
            self.isEditing = false
            self.hasUnsavedChanges = false
            self.statusMessage = "Saved \(fileURL.lastPathComponent)"
            return true
        } catch let error as JSONParseError {
            self.validationError = error.localizedDescription
            return false
        } catch {
            self.validationError = error.localizedDescription
            return false
        }
    }
}
