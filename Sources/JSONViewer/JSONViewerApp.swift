import SwiftUI
import AppKit

@main
struct JSONViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .appInfo) {
                Button("About JSON Viewer") {
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
