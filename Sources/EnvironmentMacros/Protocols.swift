//
//  Protocols.swift
//  EnvironmentMacros
//
//  Created by Joshua Toro on 10/25/24.
//

// Sources/EnvironmentMacros/Protocols.swift
public protocol PublishingContextProtocol {}
public protocol BlockElementProtocol {}
public protocol GroupElementProtocol: BlockElementProtocol {
    init<Content: BlockElementProtocol>(content: () -> [Content])
    func addCustomAttribute(name: String, value: String) -> Self
}
