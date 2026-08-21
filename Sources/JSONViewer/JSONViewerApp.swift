import SwiftUI
import AppKit

@main
struct JSONViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = JSONDocumentModel()

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
                Button("About JSON Viewer") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationVersion: "V1.1.0",
                            .version: ""
                        ]
                    )
                }
            }
        }
    }
}
