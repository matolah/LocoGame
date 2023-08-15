// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocoGame",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "LocoGame", targets: ["LocoGame"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LocoGame",
            dependencies: [],
            path: "Sources"
        )
    ]
)
