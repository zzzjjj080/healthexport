// swift-tools-version: 6.0
import PackageDescription

// UIにもHealthKitにも依存しないロジック層。
// 「値を渡したらテキストが出てくる」ところまでをここで固める。
// Xcodeを開かなくても `swift test` で回せる。
let package = Package(
    name: "HealthExportCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "HealthExportCore", targets: ["HealthExportCore"])
    ],
    targets: [
        .target(name: "HealthExportCore"),
        .testTarget(name: "HealthExportCoreTests", dependencies: ["HealthExportCore"])
    ]
)
