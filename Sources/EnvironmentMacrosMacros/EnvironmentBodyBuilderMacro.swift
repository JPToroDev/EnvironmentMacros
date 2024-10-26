//
//  EnvironmentBodyBuilderMacro.swift
//  EnvironmentMacros
//
//  Created by Joshua Toro on 10/25/24.
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct EnvironmentBodyBuilderMacro: MemberMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // Verify we're attached to a struct
        guard declaration.is(StructDeclSyntax.self) else {
            throw MacroError.requiresStruct
        }
        
        return [
                """
                private var environmentConditions: [String: String] = [:]
                """,
                """
                func addEnvironmentCondition(key: String, value: String) -> Self {
                    var copy = self
                    copy.environmentConditions[key] = value
                    return copy
                }
                """,
                """
                func checkEnvironmentConditions() -> Bool {
                    for (key, value) in environmentConditions {
                        guard let envValue = ProcessInfo.processInfo.environment[key] else {
                            return false
                        }
                        if value.hasPrefix("NOT_") {
                            let expectedValue = String(value.dropFirst(4))
                            if envValue == expectedValue {
                                return false
                            }
                        } else if envValue != value {
                            return false
                        }
                    }
                    return true
                }
                """
        ].map { DeclSyntax(stringLiteral: $0) }
    }
}

enum MacroError: Error, CustomStringConvertible {
    case requiresStruct
    
    var description: String {
        switch self {
        case .requiresStruct:
            return "@EnvironmentBodyBuilder can only be applied to a struct"
        }
    }
}
