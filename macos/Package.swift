// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhisperTeX",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WhisperTeX", targets: ["WhisperTeX"])
    ],
    targets: [
        .executableTarget(
            name: "WhisperTeX",
            path: "WhisperTeX",
            exclude: ["AppIcon.icns"]
        )
    ]
)
