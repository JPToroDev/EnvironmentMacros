// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "EnvironmentMacros",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "EnvironmentMacros",
            targets: ["EnvironmentMacros"]
        ),
        .executable(
            name: "EnvironmentMacrosClient",
            targets: ["EnvironmentMacrosClient"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-syntax.git",
            from: "509.0.0"
        ),
    ],
    targets: [
        // Macro implementation
        .macro(
            name: "EnvironmentMacrosMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        // Library that exposes the macro
        .target(
            name: "EnvironmentMacros",
            dependencies: ["EnvironmentMacrosMacros"]
        ),
        // Executable target for testing
        .executableTarget(
            name: "EnvironmentMacrosClient",
            dependencies: ["EnvironmentMacros"]
        ),
        // Test target
        .testTarget(
            name: "EnvironmentMacrosTests",
            dependencies: [
                "EnvironmentMacrosMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
