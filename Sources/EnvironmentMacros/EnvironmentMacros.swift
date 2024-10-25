// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(member, names: arbitrary)
macro EnvironmentBodyBuilder<T>(_: () -> T) -> T
