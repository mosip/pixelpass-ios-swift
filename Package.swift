// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "pixelpass",
    platforms: [
        .iOS(.v13) // Replace with minimum supported iOS version
        // Add other platforms if necessary
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "pixelpass",
            targets: ["pixelpass"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/ehn-dcc-development/base45-swift", .upToNextMajor(from: "1.1.0")),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "pixelpass",
            dependencies: ["base45-swift"]),
        .testTarget(
            name: "pixelpassTests",
            dependencies: ["pixelpass"]
        ),
    ]
)
