// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Keel",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "KeelCore", targets: ["KeelCore"]),
        .library(name: "KeeliOS", targets: ["KeeliOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", exact: "2.46.0"),
        .package(url: "https://github.com/kylef/PathKit.git", from: "1.0.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        // Stack-independent building blocks: template rendering, file trees, git.
        .target(name: "KeelCore"),
        // The iOS / iPadOS generator: models, validation, XcodeGen spec and templates.
        .target(
            name: "KeeliOS",
            dependencies: [
                "KeelCore",
                .product(name: "XcodeGenKit", package: "XcodeGen"),
                .product(name: "ProjectSpec", package: "XcodeGen"),
                .product(name: "PathKit", package: "PathKit"),
                .product(name: "Yams", package: "Yams")
            ],
            resources: [
                .copy("Resources/Templates"),
                .copy("Resources/sdk-catalog.json")
            ]
        ),
        .testTarget(name: "KeelCoreTests", dependencies: ["KeelCore"]),
        .testTarget(name: "KeeliOSTests", dependencies: ["KeeliOS"])
    ]
)
