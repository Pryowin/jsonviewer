import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: MarkdownDocumentModel
    @State private var showFullPath = true
    @State private var isPreviewingEdit = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            if let loadError = model.loadError {
                errorState(message: loadError)
            } else if model.fileURL == nil {
                emptyState
            } else if model.isEditing {
                if isPreviewingEdit {
                    MarkdownDocumentView(text: model.editableText)
                } else {
                    editorView
                }
            } else {
                MarkdownDocumentView(text: model.renderedText)
            }

            statusBar
        }
        .frame(minWidth: 560, minHeight: 420)
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Button {
                openFile()
            } label: {
                Label("Open", systemImage: "folder")
            }

            if let url = model.fileURL {
                Text(showFullPath ? url.path : url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(url.path)
                    .padding(.leading, 8)

                Button(showFullPath ? "Name Only" : "Full Path") {
                    showFullPath.toggle()
                }
                .buttonStyle(.link)
                .font(.caption)
                .help(showFullPath ? "Show just the file name" : "Show the full path")

                if showFullPath {
                    Menu {
                        Button("Reveal in Finder") {
                            revealInFinder(url)
                        }
                        Button("Open in Terminal") {
                            openInTerminal(url)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Show this file's folder in Finder or Terminal")
                }
            }

            Spacer()

            if model.fileURL != nil {
                if model.isEditing {
                    Picker("", selection: $isPreviewingEdit) {
                        Text("Edit").tag(false)
                        Text("Preview").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                    .padding(.trailing, 8)

                    Button("Cancel") {
                        model.cancelEditing()
                        isPreviewingEdit = false
                    }
                    Button("Save") {
                        model.save()
                        isPreviewingEdit = false
                    }
                    .keyboardShortcut("s", modifiers: .command)
                } else {
                    Button {
                        model.beginEditing()
                        isPreviewingEdit = false
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .padding(10)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Open a Markdown file to view it")
                .foregroundColor(.secondary)
            Text("or drag a .md file onto this window")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Open File…") { openFile() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            Button("Open a Different File…") { openFile() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusBar: some View {
        HStack {
            if let status = model.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }

    // MARK: - Editor

    private var editorView: some View {
        TextEditor(text: Binding(
            get: { model.editableText },
            set: { newValue in
                model.editableText = newValue
            }
        ))
        .font(.system(.body, design: .monospaced))
        .padding(4)
    }

    // MARK: - File handling

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            UTType(filenameExtension: "mdown") ?? .plainText,
            UTType(filenameExtension: "mkd") ?? .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            model.load(url: url)
        }
    }

    private func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func openInTerminal(_ url: URL) {
        let folder = url.deletingLastPathComponent()
        guard let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }
        NSWorkspace.shared.open([folder], withApplicationAt: terminalURL, configuration: NSWorkspace.OpenConfiguration())
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                model.load(url: url)
            }
        }
        return true
    }
}
