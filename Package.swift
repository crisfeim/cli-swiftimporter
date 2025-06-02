// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "swiftimport",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "swiftimport",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "swiftimportTests",
            dependencies: ["swiftimport"],
            resources: [.copy("files")]
        ),
    ]
)
