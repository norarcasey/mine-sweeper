// swift-tools-version: 6.0
// Swift 6 language mode: strict concurrency checking is on for every target.
import PackageDescription

let package = Package(
    name: "MineSweeperKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MineSweeperKit", targets: ["MineSweeperKit"]),
    ],
    targets: [
        .target(name: "MineSweeperKit"),
        .testTarget(name: "MineSweeperKitTests", dependencies: ["MineSweeperKit"]),
    ]
)
