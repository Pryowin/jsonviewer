import Foundation

/// Wraps a JSONValue node for display in a SwiftUI OutlineGroup, carrying an
/// optional label (object key or array index) alongside the value.
final class JSONTreeItem: Identifiable {
    let id = UUID()
    let label: String?
    let value: JSONValue
    let children: [JSONTreeItem]?

    init(label: String?, value: JSONValue) {
        self.label = label
        self.value = value
        switch value {
        case .object(let pairs):
            self.children = pairs.map { JSONTreeItem(label: $0.key, value: $0.value) }
        case .array(let items):
            self.children = items.enumerated().map { JSONTreeItem(label: "[\($0.offset)]", value: $0.element) }
        default:
            self.children = nil
        }
    }

    var isContainer: Bool {
        switch value {
        case .object, .array: return true
        default: return false
        }
    }

    var typeSummary: String {
        switch value {
        case .object(let pairs): return pairs.isEmpty ? "{}" : "{ \(pairs.count) }"
        case .array(let items): return items.isEmpty ? "[]" : "[ \(items.count) ]"
        default: return ""
        }
    }

    static func rootItems(from value: JSONValue) -> [JSONTreeItem] {
        [JSONTreeItem(label: nil, value: value)]
    }
}
