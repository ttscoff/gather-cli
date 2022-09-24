// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Gather",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/ttscoff/read-swift.git", branch: "master"),
        .package(url: "https://github.com/ttscoff/html2text-swift.git", branch: "master"),
        // .package(path: "./read-swift"),
        // .package(path: "./html2text-swift"),
        .package(url: "https://github.com/ttscoff/SwiftSoup.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "gather",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Readability", package: "read-swift"),
                .product(name: "HTML2Text", package: "html2text-swift"),
            ]
        ),
        // .testTarget(
        //     name: "gather-cliTests",
        //     dependencies: ["gather"]
        // ),
    ]
)
