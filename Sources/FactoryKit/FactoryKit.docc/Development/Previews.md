# SwiftUI Previews

Mocking dependencies for SwiftUI Previews.

## Overview

Factory can make SwiftUI Previews easier when we're using View Models and those view models depend on internal dependencies. Let's take a look.

## SwiftUI Previews

Here's an example of updating a view model's service dependency in order to setup a particular state for  preview.

```swift
// the view model
class ContentViewModel: ObservableObject {
    @Injected(\.myService) private var service
    ...
    func load() async {
        let results = await service.load()
        ...
    }
}

// the view
struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        ...
    }
}

// the preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Container.shared.myService { MockServiceN(4) }
        ContentView()
    }
}
```
If we can control where and how the view model gets its data then we can put the view model into pretty much any state we choose.

## SwiftUI #Previews

The same can be done using the new macro-based #Preview option added to Xcode 15.

```swift
#Preview {
    Container.shared.myService { MockServiceN(4) }
    ContentView()
}
```

## Multiple Registrations

There's also a variant for Containers if you need to do multiple registrations.
```swift
#Preview {
    Container.shared {
        $0.myService { MockServiceN(4) }
        $0.anotherService { MockAnotherService() }
    }
    ContentView()
}
```

## Multiple Previews

If we want to do multiple previews at once, each with different data, we simply need to instantiate our view models and pass them into the view as parameters.

Prior to Xcode 15 and given the ContentView we used above, we'd need to do:

```swift
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Container.shared.myService { MockServiceN(4) }
            let vm1 = ContentViewModel()
            ContentView(viewModel: vm1)
            
            Container.shared.myService { MockServiceN(8) }
            let vm2 = ContentViewModel()
            ContentView(viewModel: vm2)
        }
    }
}
```
Of course, it's even easier with #Preview as each one runs in its own context..
```swift
#Preview {
    Container.shared.myService { MockServiceN(4) }
    ContentView()
}
#Preview {
    Container.shared.myService { MockServiceN(0) }
    ContentView()
}
```
Since the #Preview macro has been back-ported to iOS 13, there's really no need to use the old syntax.

## Common Setup

If we have several mocks that we use all of the time in our previews or unit tests, we can also add a setup function to a given container to make this easier.

```swift
extension Container {
    func setupMocks() {
        myService { MockServiceN(4) }
        sharedService { MockService2() }
    }
}

#Preview {
    let _ = Container.shared.setupMocks()
    ContentView()
}
```
Or if you want to roll with the cool kids and continue with the preview syntax...
```swift
extension Container {
    func setupMocks() -> EmptyView {
        myService { MockServiceN(4) }
        sharedService { MockService2() }
        return EmptyView()
    }
}

#Preview {
    Container.shared.setupMocks()
    ContentView()
}
```

## Preview Traits

Xcode 16 added composable traits to the macro-based `#Preview`, and Factory ships a set of them so mocks can be registered *declaratively*, as part of the preview's declaration, rather than as a statement inside the preview's body.

```swift
#Preview(traits: .register(\.myService) { MockService() }) {
    ContentView()
}
```

This resolves the same dependency graph as registering inline (as shown above), but utilising a more idomatic and clean way. 

### Registering a Single Factory

`.register` overrides one factory on the default `Container`.

```swift
#Preview(traits: .register(\.myService) { MockService() }) {
    ContentView()
}
```

### Registering on a Custom Container

Point the key path at a custom container type and Factory infers the container.

```swift
#Preview(traits: .register(\PaymentsContainer.processor) { MockProcessor() }) {
    ContentView()
}
```

### Multiple Registrations

`.container` hands you a transformer closure over the whole container, mirroring `Container.shared { ... }`, for when a preview needs more than one mock.

```swift
#Preview(traits: .container { container in
    container.myService { MockService() }
    container.anotherService { MockAnother() }
}) {
    ContentView()
}
```

### Multiple Registrations on a Custom Container

Annotate the closure's parameter with the container type you want and Factory infers it, the same way the single-factory `.register` form infers its container from the key path.

```swift
#Preview(traits: .container { (container: PaymentsContainer) in
    container.processor { MockProcessor() }
    container.ledger { MockLedger() }
}) {
    ContentView()
}
```

### Combining Traits Across Containers

`#Preview` traits are variadic, so `.register` and `.container` calls can be mixed and matched — including across different container types — in a single preview.

```swift
#Preview(traits:
    .register(\.myService) { MockService() },
    .register(\PaymentsContainer.processor) { MockProcessor() }
) {
    ContentView()
}
```

> Important: Preview traits require iOS 18 / macOS 15 / tvOS 18 / watchOS 11 / visionOS 2 / macCatalyst 18 or later, since they build on the `PreviewModifier` trait system Apple introduced that release. On earlier OS versions, register inline in the preview body instead, as shown above.

