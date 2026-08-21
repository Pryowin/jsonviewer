import SwiftUI

/// Renders one JSON node and, recursively, its children. Every container
/// starts fully expanded, and each nesting level adds a fixed indent so the
/// hierarchy reads top-to-bottom on the left edge instead of being centered.
struct JSONNodeView: View {
    let item: JSONTreeItem
    let depth: Int

    @State private var isExpanded: Bool = true

    private let indentWidth: CGFloat = 16
    private let chevronWidth: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let children = item.children {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: chevronWidth, alignment: .center)
                        JSONRowView(item: item)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(children) { child in
                            JSONNodeView(item: child, depth: depth + 1)
                        }
                    }
                    .padding(.leading, indentWidth)
                }
            } else {
                HStack(spacing: 4) {
                    Color.clear.frame(width: chevronWidth, height: 1)
                    JSONRowView(item: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
