import SwiftUI

/// Color scheme used to render JSON tokens, loosely matching common code editor themes.
enum JSONColors {
    static let key = Color(red: 0.45, green: 0.15, blue: 0.75)      // purple
    static let string = Color(red: 0.77, green: 0.10, blue: 0.09)   // red
    static let number = Color(red: 0.11, green: 0.45, blue: 0.85)   // blue
    static let bool = Color(red: 0.80, green: 0.45, blue: 0.05)     // orange
    static let null = Color.secondary
    static let punctuation = Color.secondary
}

struct JSONRowView: View {
    let item: JSONTreeItem

    var body: some View {
        HStack(spacing: 4) {
            if let label = item.label {
                Text(label)
                    .foregroundColor(item.label?.hasPrefix("[") == true ? JSONColors.punctuation : JSONColors.key)
                    .fontWeight(.medium)
                Text(":")
                    .foregroundColor(JSONColors.punctuation)
            }

            valueView
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .font(.system(.body, design: .monospaced))
    }

    @ViewBuilder
    private var valueView: some View {
        switch item.value {
        case .object, .array:
            Text(item.typeSummary)
                .foregroundColor(JSONColors.punctuation)
        case .string(let s):
            Text("\"\(s)\"")
                .foregroundColor(JSONColors.string)
        case .number(let n):
            Text(n)
                .foregroundColor(JSONColors.number)
        case .bool(let b):
            Text(b ? "true" : "false")
                .foregroundColor(JSONColors.bool)
        case .null:
            Text("null")
                .foregroundColor(JSONColors.null)
        }
    }
}
