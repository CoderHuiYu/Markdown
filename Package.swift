// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MarkdownEditor",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "MarkdownEditor",
            targets: ["MarkdownEditor"]
        ),
    ],
    targets: [
        .target(
            name: "MarkdownEditor",
            resources: [
                .copy("Resources/Vditor"),
                .process("Resources/PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "MarkdownEditorTests",
            dependencies: ["MarkdownEditor"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
