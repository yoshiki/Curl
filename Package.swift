import PackageDescription

let package = Package(
    name: "Curl",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/CCurl.git", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/Zewo/JSON.git", majorVersion: 0, minor: 12),
    ]
)
