import SwiftUI

/// Renders parsed Markdown as a flat, top-to-bottom flow of styled blocks.
/// There is deliberately no collapsing/disclosure here — every block is
/// always fully visible, unlike the JSON viewer's collapsible tree.
struct MarkdownDocumentView: View {
    let text: String

    private var blocks: [MarkdownBlock] {
        MarkdownBlockParser.parse(text)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(blocks) { block in
                    blockView(for: block)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading(let level):
            Text(block.content)
                .font(headingFont(for: level))
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, level <= 2 ? 6 : 2)

        case .paragraph:
            Text(block.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .codeBlock(let language):
            codeBlockView(block: block, language: language)

        case .blockQuote(let indent):
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 3)
                Text(block.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(indent) * 20)

        case .unorderedListItem(let indent):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                Text(block.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(indent) * 20)

        case .orderedListItem(let ordinal, let indent):
            HStack(alignment: .top, spacing: 8) {
                Text("\(ordinal).")
                    .font(.body.monospacedDigit())
                Text(block.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(indent) * 20)

        case .thematicBreak:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func codeBlockView(block: MarkdownBlock, language: String?) -> some View {
        let code = String(block.content.characters).trimmingCharacters(in: .newlines)
        return VStack(alignment: .leading, spacing: 4) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ScrollView(.horizontal) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.12)))
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .system(size: 26)
        case 2: return .system(size: 21)
        case 3: return .system(size: 18)
        case 4: return .system(size: 16)
        case 5: return .system(size: 14)
        default: return .system(size: 13)
        }
    }
}
