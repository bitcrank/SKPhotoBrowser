// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SKPhotoBrowser",
    products: [
        .library(name: "SKPhotoBrowser", targets: ["SKPhotoBrowser"])
    ],
    targets:[
        .target(name: "SKPhotoBrowser", dependencies: [], path: "SKPhotoBrowser"),
    ]
)
