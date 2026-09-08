// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "swit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "swit",
            targets: ["Swit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "1.5.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "Swit",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        ),
        .testTarget(
            name: "SwitTests",
            dependencies: ["Swit"]
        ),
    ]
)
