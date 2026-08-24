import SwiftUI
import AppKit

@main
struct MarkdownViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = MarkdownDocumentModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onAppear {
                    appDelegate.attach(model: model)
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("About Markdown Viewer") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationVersion: "V1.0.0",
                            .version: ""
                        ]
                    )
                }
            }
        }
    }
}
