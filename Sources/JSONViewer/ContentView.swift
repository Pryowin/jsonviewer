import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: JSONDocumentModel

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            Divider()

            if let loadError = model.loadError {
                errorState(message: loadError)
            } else if model.rootValue == nil {
                emptyState
            } else if model.isEditing {
                editorView
            } else {
                treeView
            }

            if let validationError = model.validationError, model.isEditing {
                validationBanner(message: validationError)
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
                Text(url.path)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(url.path)
                    .padding(.leading, 8)

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

            Spacer()

            if model.rootValue != nil {
                if model.isEditing {
                    Button("Cancel") {
                        model.cancelEditing()
                    }
                    Button("Save") {
                        model.save()
                    }
                    .disabled(!model.isValidJSON)
                    .keyboardShortcut("s", modifiers: .command)
                } else {
                    Button {
                        model.beginEditing()
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
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Open a JSON file to view it")
                .foregroundColor(.secondary)
            Text("or drag a .json file onto this window")
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

    private func validationBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
            Text("Invalid JSON — \(message)")
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
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

    // MARK: - Tree / Editor

    private var treeView: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(model.rootItems) { item in
                    JSONNodeView(item: item, depth: 0)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 0, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var editorView: some View {
        TextEditor(text: Binding(
            get: { model.editableText },
            set: { newValue in
                model.editableText = newValue
                model.validate()
            }
        ))
        .font(.system(.body, design: .monospaced))
        .padding(4)
    }

    // MARK: - File handling

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
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
