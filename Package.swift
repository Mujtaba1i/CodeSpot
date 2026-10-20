// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CodeSpot",
    platforms: [.macOS(.v14)],
    targets: [.executableTarget(name: "CodeSpot", path: "Sources/CodeSpot")]
)
