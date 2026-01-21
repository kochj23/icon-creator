// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IconCreatorCLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "icon-creator",
            targets: ["IconCreatorCLI"]
        )
    ],
    dependencies: [
        // Vapor for webhook server
        .package(url: "https://github.com/vapor/vapor.git", from: "4.89.0"),
    ],
    targets: [
        .executableTarget(
            name: "IconCreatorCLI",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ],
            path: "Sources"
        )
    ]
)
