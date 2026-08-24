import Foundation

/// A single top-level rendering unit (heading, paragraph, list item, etc.)
/// produced by grouping Foundation's block-level Markdown parse.
struct MarkdownBlock: Identifiable {
    let id: Int
    let kind: Kind
    let content: AttributedString

    enum Kind {
        case heading(level: Int)
        case paragraph
        case codeBlock(language: String?)
        case blockQuote(indent: Int)
        case unorderedListItem(indent: Int)
        case orderedListItem(ordinal: Int, indent: Int)
        case thematicBreak
    }
}

enum MarkdownBlockParser {
    private static let options = AttributedString.MarkdownParsingOptions(
        allowsExtendedAttributes: true,
        interpretedSyntax: .full,
        failurePolicy: .returnPartiallyParsedIfPossible
    )

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        guard let attributed = try? AttributedString(markdown: markdown, options: options) else {
            return [MarkdownBlock(id: 0, kind: .paragraph, content: AttributedString(markdown))]
        }
        return groupIntoBlocks(attributed)
    }

    /// Foundation's parser tags every run with a `PresentationIntent` whose
    /// innermost component carries a stable `identity` per block (paragraph,
    /// list item, heading, ...). Runs are grouped wherever that identity
    /// changes to reconstruct the block boundaries.
    private static func groupIntoBlocks(_ attributed: AttributedString) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var blockStart = attributed.startIndex
        var keyInitialized = false
        var currentKey: Int?
        var currentIntent: PresentationIntent?

        func closeBlock(end: AttributedString.Index) {
            guard blockStart < end else { return }
            let slice = AttributedString(attributed[blockStart..<end])
            blocks.append(MarkdownBlock(id: blocks.count, kind: classify(currentIntent), content: slice))
        }

        for run in attributed.runs {
            let key = run.presentationIntent?.components.first?.identity
            if !keyInitialized {
                keyInitialized = true
                currentKey = key
                currentIntent = run.presentationIntent
            } else if key != currentKey {
                closeBlock(end: run.range.lowerBound)
                blockStart = run.range.lowerBound
                currentKey = key
                currentIntent = run.presentationIntent
            }
        }
        closeBlock(end: attributed.endIndex)
        return blocks
    }

    private static func classify(_ intent: PresentationIntent?) -> MarkdownBlock.Kind {
        guard let intent else { return .paragraph }
        let components = intent.components

        for component in components {
            if case .header(let level) = component.kind { return .heading(level: level) }
            if case .codeBlock(let languageHint) = component.kind { return .codeBlock(language: languageHint) }
            if case .thematicBreak = component.kind { return .thematicBreak }
        }

        for (index, component) in components.enumerated() {
            if case .listItem(let ordinal) = component.kind {
                let isOrdered = index + 1 < components.count && isOrderedListKind(components[index + 1].kind)
                let indent = max(intent.indentationLevel - 1, 0)
                return isOrdered
                    ? .orderedListItem(ordinal: ordinal, indent: indent)
                    : .unorderedListItem(indent: indent)
            }
        }

        if components.contains(where: { if case .blockQuote = $0.kind { return true } else { return false } }) {
            return .blockQuote(indent: max(intent.indentationLevel - 1, 0))
        }

        return .paragraph
    }

    private static func isOrderedListKind(_ kind: PresentationIntent.Kind) -> Bool {
        if case .orderedList = kind { return true }
        return false
    }
}
