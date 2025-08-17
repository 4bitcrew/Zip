// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Zip",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Zip", targets: ["Zip"])
    ],
    targets: [
        .target(
            name: "Minizip",
            dependencies: [],
            path: "Zip/minizip",
            exclude: ["module"],
            linkerSettings: [
                .linkedLibrary("z")
            ]),
        .target(
            name: "Zip",
            dependencies: ["Minizip"],
            path: "Zip",
            exclude: ["minizip", "zlib"]),
        .testTarget(
            name: "ZipTests",
            dependencies: ["Zip"],
            path: "ZipTests"),
    ]
)
