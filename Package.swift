// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Backdrop",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Backdrop", path: "Sources/Backdrop")
    ]
)
