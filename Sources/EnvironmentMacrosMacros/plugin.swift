//
//  Untitled.swift
//  EnvironmentMacros
//
//  Created by Joshua Toro on 10/25/24.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct EnvironmentMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EnvironmentBodyBuilderMacro.self,
    ]
}
