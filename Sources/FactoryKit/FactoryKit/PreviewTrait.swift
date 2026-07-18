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
    ///   - path: Key path to the factory on `Container` to override.
    ///   - factory: Closure returning the mock instance to register.
    public static func register<S>(
        _ path: KeyPath<Container, Factory<S>> & Sendable,
        _ factory: @escaping @Sendable () -> S
    ) -> Self {
        .modifier(FactoryPreviewTrait(path: path, factory: factory))
    }

    /// Registers a preview override for a factory on the given container type.
    /// ```swift
    /// #Preview(traits: .register(on: PaymentsContainer.self, \.processor) { MockProcessor() }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameters:
    ///   - container: The `SharedContainer` type that owns the factory.
    ///   - path: Key path to the factory on `container` to override.
    ///   - factory: Closure returning the mock instance to register.
    public static func register<C: SharedContainer, S>(
        on container: C.Type,
        _ path: KeyPath<C, Factory<S>> & Sendable,
        _ factory: @escaping @Sendable () -> S
    ) -> Self {
        .modifier(FactoryPreviewTrait(path: path, factory: factory))
    }

    /// Performs multiple registrations on the given container type, mirroring `Container.preview { ... }`.
    /// ```swift
    /// #Preview(traits: .container { container in
    ///     container.myService.register { MockService() }
    ///     container.anotherService.register { MockAnother() }
    /// }) {
    ///     ContentView()
    /// }
    /// ```
    /// - Parameter setup: Closure that performs registrations on the default `Container`.
    public static func container(
        _ setup: @escaping @Sendable (Container) -> Void
    ) -> Self {
        .modifier(FactoryContainerPreviewTrait<Container>(setup: setup))
    }

    /// Performs multiple registrations on a custom container type.
    /// - Parameters:
    ///   - container: The `SharedContainer` type to set up.
    ///   - setup: Closure that performs registrations on `container`.
    public static func container<C: SharedContainer>(
        _ container: C.Type,
        _ setup: @escaping @Sendable (C) -> Void
    ) -> Self {
        .modifier(FactoryContainerPreviewTrait<C>(setup: setup))
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
struct FactoryPreviewTrait<C: SharedContainer, S>: PreviewModifier {

    let path: KeyPath<C, Factory<S>> & Sendable
    let factory: @Sendable () -> S

    init(path: KeyPath<C, Factory<S>> & Sendable, factory: @escaping @Sendable () -> S) {
        self.path = path
        self.factory = factory
        C.shared[keyPath: path].register(factory: factory)
    }

    func body(content: Content, context _: Void) -> some View {
        // Previews share a process and Xcode gives no timing guarantees for init,
        // so re-assert the registration on every render. Registration is idempotent.
        C.shared[keyPath: path].register(factory: factory)
        return content
    }

}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
struct FactoryContainerPreviewTrait<C: SharedContainer>: PreviewModifier {

    let setup: @Sendable (C) -> Void

    init(setup: @escaping @Sendable (C) -> Void) {
        self.setup = setup
        setup(C.shared)
    }

    func body(content: Content, context _: Void) -> some View {
        setup(C.shared)
        return content
    }

}

// MARK: - Examples

#if DEBUG

private protocol ExampleGreeting: Sendable {
    var text: String { get }
}

private struct LiveGreeting: ExampleGreeting {
    let text = "Hello from Live"
}

private struct MockGreeting: ExampleGreeting {
    let text = "Hello from Mock"
}

extension Container {
    fileprivate var exampleGreeting: Factory<ExampleGreeting> {
        self { LiveGreeting() }
    }
    fileprivate var anotherGreeting: Factory<ExampleGreeting> {
        self { LiveGreeting() }
    }
}

private final class ExamplePreviewContainer: SharedContainer, @unchecked Sendable {
    @TaskLocal static var shared = ExamplePreviewContainer()
    let manager = ContainerManager()
}

extension ExamplePreviewContainer {
    fileprivate var exampleGreeting: Factory<ExampleGreeting> {
        self { LiveGreeting() }
    }
    fileprivate var anotherGreeting: Factory<ExampleGreeting> {
        self { LiveGreeting() }
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
#Preview("Single registration", traits: .register(\.exampleGreeting) { MockGreeting() }) {
    Text(Container.shared.exampleGreeting().text)
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
#Preview("Custom container", traits: .register(on: ExamplePreviewContainer.self, \.exampleGreeting) { MockGreeting() }) {
    Text(ExamplePreviewContainer.shared.exampleGreeting().text)
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
#Preview("Multiple registrations", traits: .container { container in
    container.exampleGreeting.register { MockGreeting() }
    container.anotherGreeting.register { MockGreeting() }
}) {
    VStack {
        Text(Container.shared.exampleGreeting().text)
        Text(Container.shared.anotherGreeting().text)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, macCatalyst 18.0, *)
#Preview("Multiple registrations on custom container", traits: .container(ExamplePreviewContainer.self) { container in
    container.exampleGreeting.register { MockGreeting() }
    container.anotherGreeting.register { MockGreeting() }
}) {
    VStack {
        Text(ExamplePreviewContainer.shared.exampleGreeting().text)
        Text(ExamplePreviewContainer.shared.anotherGreeting().text)
    }
}

#endif

#endif
