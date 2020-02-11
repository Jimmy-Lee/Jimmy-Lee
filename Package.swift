// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "JimmyLee",
    products: [
        .executable(name: "JimmyLee", targets: ["JimmyLee"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/publish.git", from: "0.3.0"),
        .package(url: "https://github.com/johnsundell/splashpublishplugin", from: "0.1.0"),
        .package(path: "../Splash")
    ],
    targets: [
        .target(
            name: "JimmyLee",
            dependencies: ["Publish", "SplashPublishPlugin"]
        )
    ]
)
