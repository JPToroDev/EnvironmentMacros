import SwiftSyntaxMacros

// Sources/EnvironmentMacros/EnvironmentMacros.swift
/// A macro that generates environment condition checking code
@attached(member, names: arbitrary)
public macro EnvironmentBodyBuilder() = #externalMacro(module: "EnvironmentMacros", type: "EnvironmentBodyBuilderMacro")
