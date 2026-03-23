// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JoyMapKit",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "JoyMapKitCore", targets: ["JoyMapKitCore"]),
        .executable(name: "JoyMapKitApp", targets: ["JoyMapKitApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "JoyMapKitCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            linkerSettings: [
                .linkedFramework("GameController"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AppKit"),
            ]
        ),
        .executableTarget(
            name: "JoyMapKitApp",
            dependencies: [
                "JoyMapKitCore",
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
            ]
        ),
        .testTarget(
            name: "JoyMapKitCoreTests",
            dependencies: ["JoyMapKitCore"]
        ),
    ]
)
