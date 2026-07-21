//
// PreviewTrait.swift
//
// GitHub Repo and Documentation: https://github.com/hmlongco/Factory
//
// Copyright © 2022-2025 Michael Long. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SO

#if canImport(SwiftUI)
public import SwiftUI

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
extension PreviewTrait where T == Preview.ViewTraits {

    /// Registers a preview override for a factory on the default `Container`.
    /// ```swift
    /// #Preview(traits: .register(\.myService) { MockService() }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameters:
    ///   - keyPath: KeyPath to a Factory on the specified Container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public static func register<S>(
        _ keyPath: KeyPath<Container, Factory<S>>,
        _ factory: @escaping @Sendable () -> S
    ) -> Self {
        .modifier(FactoryPreviewTrait(keyPath: keyPath, factory: factory))
    }

    /// Registers a preview override for a factory on a custom container type.
    /// ```swift
    /// #Preview(traits: .register(\PaymentsContainer.processor) { MockProcessor() }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameters:
    ///   - keyPath: KeyPath to a Factory on the specified Container.
    ///   - factory: A factory closure that produces an object of the desired type when required.
    public static func register<C: SharedContainer, S>(
        _ keyPath: KeyPath<C, Factory<S>>,
        _ factory: @escaping @Sendable () -> S
    ) -> Self {
        .modifier(FactoryPreviewTrait(keyPath: keyPath, factory: factory))
    }

    /// Performs multiple registrations on the default `Container`, mirroring `Container.preview { ... }`.
    /// ```swift
    /// #Preview(traits: .container { container in
    ///     container.myService { MockService() }
    ///     container.anotherService { MockAnother() }
    /// }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameter transform: Closure that performs registrations on the default `Container`.
    public static func container(
        _ transform: @escaping (Container) -> Void
    ) -> Self {
        .modifier(FactoryContainerPreviewTrait<Container>(transform: transform))
    }

    /// Performs multiple registrations on a custom container type, inferred from the closure's parameter type.
    /// ```swift
    /// #Preview(traits: .container { (container: PaymentsContainer) in
    ///     container.myService { MockService() }
    ///     container.anotherService { MockAnother() }
    /// }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameter transform: Closure that performs registrations on the custom container.
    public static func container<C: SharedContainer>(
        _ transform: @escaping (C) -> Void
    ) -> Self {
        .modifier(FactoryContainerPreviewTrait<C>(transform: transform))
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
struct FactoryPreviewTrait<C: SharedContainer, S>: PreviewModifier {

    let keyPath: KeyPath<C, Factory<S>>
    let factory: @Sendable () -> S

    init(keyPath: KeyPath<C, Factory<S>>, factory: @escaping @Sendable () -> S) {
        self.keyPath = keyPath
        self.factory = factory
        C.shared[keyPath: keyPath].register(factory: factory)
    }

    func body(content: Content, context _: Void) -> some View {
        // Previews share a process and Xcode gives no timing guarantees for init,
        // so re-assert the registration on every render. Registration is idempotent.
        C.shared[keyPath: keyPath].register(factory: factory)
        return content
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
struct FactoryContainerPreviewTrait<C: SharedContainer>: PreviewModifier {

    let transform: (C) -> Void

    init(transform: @escaping (C) -> Void) {
        self.transform = transform
        transform(C.shared)
    }

    func body(content: Content, context _: Void) -> some View {
        transform(C.shared)
        return content
    }

}

#endif
