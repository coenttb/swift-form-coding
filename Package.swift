// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "swift-form-coding",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "FormCoding", targets: ["FormCoding"])
    ],
    dependencies: [
        .package(path: "../swift-url-form-coding"),
        .package(path: "../swift-multipart-form-coding")
    ],
    targets: [
        .target(
            name: "FormCoding",
            dependencies: [
                .product(name: "URLFormCoding", package: "swift-url-form-coding"),
                .product(name: "URLFormCodingURLRouting", package: "swift-url-form-coding"),
                .product(name: "MultipartFormCoding", package: "swift-multipart-form-coding"),
                .product(name: "MultipartFormCodingURLRouting", package: "swift-multipart-form-coding")
            ]
        )
    ]
)
