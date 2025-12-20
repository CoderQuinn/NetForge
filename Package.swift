// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetForge",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NetForge",
            targets: ["NetForge"]
        ),
    ],
    dependencies: [
        // Core TUN stack utilities (local path)
        .package(path: "../TunForge"),
        // DNS handling utilities (local path)
        .package(path: "../EchoForgeDNS"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NetForge",
            dependencies: [
                .product(name: "TunForgeCore", package: "TunForge"),
                .product(name: "EchoForgeDNS", package: "EchoForgeDNS"),
            ]
        ),
        .testTarget(
            name: "NetForgeTests",
            dependencies: ["NetForge"]
        ),
    ]
)
