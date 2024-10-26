// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that generates environment condition checking code
@attached(peer, names: arbitrary)
public macro EnvironmentBodyBuilder() = #externalMacro(module: "EnvironmentMacrosMacros", type: "EnvironmentBodyBuilderMacro")
