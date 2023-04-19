// swift-tools-version:5.8
import PackageDescription

let package = Package(
  name: "Swana",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .executable(
      name: "swana",
      targets: ["Swana"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pakLebah/ANSITerminal", .upToNextMajor(from: "0.0.3")),
    .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.1.4")),
    .package(url: "https://github.com/apple/swift-syntax", .upToNextMajor(from: "508.0.0")),
  ],
  targets: [
    .executableTarget(
      name: "Swana",
      dependencies: [
        .product(name: "ANSITerminal", package: "ANSITerminal"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
      ],
      path: "Sources"
    ),
    .testTarget(
      name: "SwanaTests",
      dependencies: ["Swana"],
      path: "Tests"
    ),
  ]
)
