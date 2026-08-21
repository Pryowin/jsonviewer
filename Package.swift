// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JSONViewer",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "JSONViewer",
            path: "Sources/JSONViewer"
        )
    ]
)
