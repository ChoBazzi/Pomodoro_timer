// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PomodoroTimer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PomodoroTimer", targets: ["PomodoroTimer"])
    ],
    targets: [
        .executableTarget(
            name: "PomodoroTimer"
        )
    ]
)
