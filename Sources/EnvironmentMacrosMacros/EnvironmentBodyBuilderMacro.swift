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

public struct EnvironmentBodyBuilderMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self),
              funcDecl.name.text == "body" else {
            throw MacroError.requiresBodyFunction
        }
                
        return ["""
        func processEnvironmentBody<PC: PublishingContextProtocol, BE: BlockElementProtocol>(
            context: PC,
            groupType: BE.Type
        ) -> [BE] where BE: GroupElementProtocol {
            var elements = [BE]()
            
            for element in body(context: context) {
                var environmentAttributes = [String: String]()
                
                // Find environment values
                let mirror = Mirror(reflecting: self)
                for child in mirror.children {
                    if let envKey = child.label?.replacingOccurrences(of: "_", with: ""),
                       type(of: child.value).self == Environment<Any>.self {
                        environmentAttributes[envKey.lowercased()] = String(describing: child.value)
                    }
                }
                
                let wrapped = BE(content: {
                    [element]
                })
                
                // Apply each environment attribute
                let processedElement = environmentAttributes.reduce(wrapped) { element, attr in
                    element.addCustomAttribute(name: "data-ignite-env-\\(attr.key)", value: attr.value)
                }
                
                elements.append(processedElement)
            }
            
            return elements
        }
        """]
    }
}

enum MacroError: Error, CustomStringConvertible {
    case requiresBodyFunction
    
    var description: String {
        switch self {
        case .requiresBodyFunction:
            return "@EnvironmentBodyBuilder can only be applied to the body function"
        }
    }
}
