// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "WBAlamofire",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", Version(4, 5, 0)..<Version(5, 0, 0))
    ],
    swiftLanguageVersions: [4]
)
